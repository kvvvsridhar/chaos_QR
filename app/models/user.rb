class User < ApplicationRecord
    validates :id_number, presence: true, uniqueness: true
    validate :id_number_exists, on: :update # Validation runs during update

  private

  def id_number_exists
    unless User.exists?(id_number: id_number)
      errors.add(:id_number, "is not valid. Please scan a QR code of a registered user.")
    end
  end
end
