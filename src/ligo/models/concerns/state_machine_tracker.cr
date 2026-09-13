class AASM::StateMachine
  setter current_state_name
end

# Generic helper for database-backed AASM state machines.
# Model-specific concerns can include this module and call the
# private macro below with their field, enum, states, and events.
# TLDR: allows a model to act-as-a-state-machine with db-backed state
module StateMachineTracker
  macro included
    include AASM # include aasm if not already
  end

  private macro state_machine(field_name, enum_type, initial_state, states, events)
    field :{{field_name.id}}, :int, default: {{enum_type}}::{{initial_state.id}}.value

    after_initialize :act_as_state_machine
    after_initialize :sync_aasm_state!
    before_save :sync_aasm_state!

    def act_as_state_machine
      {% for state_name, state_config in states %}
        {% enter_callback = nil %}
        {% guard_callback = nil %}
        {% if state_config.is_a?(NamedTupleLiteral) %}
          {% enter_callback = state_config[:enter] %}
          {% guard_callback = state_config[:guard] %}
        {% end %}

        {% if state_name.id == initial_state.id %}
          aasm.state :{{state_name.id}}, initial: true{% if enter_callback %}, enter: {{enter_callback}}{% end %}{% if guard_callback %}, guard: {{guard_callback}}{% end %}
        {% else %}
          aasm.state :{{state_name.id}}{% if enter_callback %}, enter: {{enter_callback}}{% end %}{% if guard_callback %}, guard: {{guard_callback}}{% end %}
        {% end %}
      {% end %}

      {% for event_name, event_config in events %}
        aasm.event :{{event_name.id}} do |e|
          {% from_states = event_config[:from] %}
          {% to_state = event_config[:to] %}
          e.transitions from: {{from_states}}, to: :{{to_state.id}}
        end
      {% end %}
    end

    def change_{{field_name.id}}!(event_sym : Symbol)
      # before going further, make sure AASM is in sync with persisted field value
      sync_aasm_state!

      to_state_sym = {{enum_type}}.from_event(event_sym).to_state
      return if state && state.to_s == to_state_sym.to_s # makes sure idempotent

      fire!(event_sym)

      new_state = aasm.current_state_name
      enum_value = {{enum_type}}.parse(new_state.to_s)

      self.{{field_name.id}} = enum_value.value
    end

    def may_{{field_name.id}}_event?(event_sym : Symbol) : Bool
      current = {{enum_type}}.from_value?({{field_name.id}}!).try(&.to_state)
      return false unless current

      case event_sym
      {% for event_name, event_config in events %}
      {% from = event_config[:from] %}
      when :{{event_name.id}}
        {% if from.is_a?(SymbolLiteral) %}
        :{{from.id}} == current
        {% else %}
        {{from}}.includes?(current)
        {% end %}
      {% end %}
      else
        false
      end
    end

    private def sync_aasm_state!
      return unless {{field_name.id}}?

      state_value = {{enum_type}}.from_value?({{field_name.id}}!)
      return unless state_value

      aasm.current_state_name = state_value.to_state
    end
  end
end
