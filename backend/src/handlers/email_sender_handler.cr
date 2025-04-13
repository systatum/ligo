class EmailSenderHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  class Receiver
    @email : String
    @first_name : String
    @last_name : String

    def initialize(@email : String, @first_name : String, @last_name : String)
    end

    def email
      @email
    end

    def first_name
      @first_name
    end

    def last_name
      @last_name
    end
  end

  def get
    candidates_csv_text = File.read("./candidates.csv")
    candidates_csv = CSV.new(candidates_csv_text, headers: true)

    config = EMail::Client::Config.new(
      "smtp-mail.outlook.com",
      587,
      helo_domain: "systatum.com"
    )
    config.use_tls(EMail::Client::TLSMode::SMTPS)
    config.use_tls(EMail::Client::TLSMode::STARTTLS)

    config.use_auth("adam@systatum.com", "goa*squeals2miller")
    sender = EMail::ConcurrentSender.new(config)
    sender.number_of_connections = 3
    sender.messages_per_connection = 3
    sender.start do
      receivers = [] of Receiver
      candidates_csv.each do |row|
        receivers << Receiver.new(
          email: row["Email"],
          first_name: row["First name"],
          last_name: row["Last name"],
        )
      end

      sender = EMail::Address.new("adam@systatum.com", "#{"Adam".capitalize} #{"Hakarsa".capitalize}")
      receivers.each do |receiver|
        mail = EMail::Message.new
        mail.from sender
        mail.to receiver.email
        mail.cc ["salwa@systatum.com", "adb819@g.harvard.edu"]
        mail.subject "Let's advance at Dashtomer!"
        person_full_name = "#{receiver.first_name} #{receiver.last_name}"
        # message_text = <<-EOM
        # Hi #{person_full_name},

        # I hope you're doing well.

        # I am Adam Hakarsa, the founder of Dashtomer. I wanted to personally congratulate you and let you know that I am truly impressed by your application. We’re excited to move forward with you and we invite you to complete our take-home test; please find the full details in the attached document.

        # You have a full three weeks to complete and submit the test.

        # Please feel free to ping me back if anything. I look forward to seeing your submission.

        # Best,
        # Adam
        # Dashtomer, a part of Systatum
        # EOM

        message_text = <<-EOM
        Dear #{person_full_name},

        I hope things going smoothly with your studies and life in general.

        I am Adam, the CEO of Dashtomer (Systatum). I would like to know you and your aspiration better. When you have a moment, could you please take 10–20 minutes to complete the following questionnaire?

        https://forms.office.com/r/JZzBGXEnuD

        It would be great if you could submit it by the end of Apr 17, 2025.

        Thank you.

        Best,
        Adam
        Dashtomer, a part of Systatum
        EOM

        mail.message message_text
        # mail.attach "./Backend - April 26.pdf"
        enqueue mail
      end
    end
    json "{}", status: 200
  end
end
