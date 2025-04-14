class EmailSenderHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  def get
    candidates_csv_text = File.read("./candidates.csv")
    candidates_csv = CSV.new(candidates_csv_text, headers: true)
    candidates_csv.each do |row|
      shortlisted_intern_text = <<-EOM
      Dear #{row["First name"]} #{row["Last name"]},

      I hope things going smoothly with your studies and life in general.

      I am Adam, the CEO of Dashtomer (Systatum). I would like to know you and your aspiration better. When you have a moment, could you please take 10–20 minutes to complete the following questionnaire?

      https://forms.office.com/r/JZzBGXEnuD

      It would be great if you could submit it by the end of Apr 17, 2025.

      Thank you.

      Best,
      Adam
      Dashtomer, a part of Systatum
      EOM

      message_text = <<-EOM
      Dear #{row["First name"]} #{row["Last name"]},

      I hope you're doing well.

      I am Adam Hakarsa, the founder of Dashtomer. I wanted to personally congratulate you and let you know that I am truly impressed by your application. We’re excited to move forward with you and we invite you to complete our take-home test; please find the full details in the attached document.

      You have a full three weeks to complete and submit the test.

      Please feel free to ping me back if anything. I look forward to seeing your submission.

      Best,
      Adam
      Dashtomer, a part of Systatum
      EOM

      email = Workaty::GenericEmail.new(
        receiver_email: row["Email"],
        receiver_name: "#{row["First name"]} #{row["Last name"]}",
        sender_email: "adam@hakarsa.com",
        sender_name: "Adam Hakarsa",
        subject: "Let's advance at Dashtomer!",
        content: message_text,
      )

      email.deliver
    end

    return json "{}", status: 200
  end
end
