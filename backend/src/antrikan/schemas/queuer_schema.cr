module Antrikan
  BaseSchema.with_fields(
    fields: {
      queuer_id:    {type: :string},
      password:     {type: :string},
      name:         {type: :string, max_size: 255, strip: true},
      home_address: {type: :string, max_size: 255, strip: true},
      mobile_phone: {type: :string, max_size: 20, strip: true},
      note:         {type: :string, max_size: 255, strip: true},
      user_id:      {type: :string},
    },
    variants: {
      QueuerSchema:       {required: [:name]},
      QueuerUpdateSchema: {required: [:queuer_id, :password]},
    }
  )
end
