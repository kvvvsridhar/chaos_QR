class User < ApplicationRecord
    validates :id_number, presence: true, uniqueness: true
    validate :id_number_exists, on: :update # Validation runs during update

    # Generate QR code for the user and save its file path
  def generate_and_save_qr_code
    qr_data = {
      "name": self.name,
      "age": self.age,
      "id_number": self.id_number
    }.to_json

    # Generate QR code
    qr_code = RQRCode::QRCode.new(qr_data)
    qr_file_path = Rails.root.join('public', 'qr_codes', "#{self.id_number}_qr.png")
    FileUtils.mkdir_p(File.dirname(qr_file_path))
    IO.binwrite(qr_file_path, qr_code.as_png(size: 300, border_modules: 2).to_s)

    # Update user record with QR code file path
    self.update!(qr_code: qr_file_path.relative_path_from(Rails.root.join('public')).to_s)
  end

  private

  def id_number_exists
    unless User.exists?(id_number: id_number)
      errors.add(:id_number, "is not valid. Please scan a QR code of a registered user.")
    end
  end
end
