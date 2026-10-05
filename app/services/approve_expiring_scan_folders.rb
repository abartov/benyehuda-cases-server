# Postponed folders whose copyright expires next year become approved, so work can
# start this year.
class ApproveExpiringScanFolders
  def self.call(today: Time.zone.today)
    count = ScanFolder.where(status: 'postponed', copyright_expiration_year: today.year + 1)
                      .update_all(status: 'approved', updated_at: Time.zone.now)
    Rails.logger.info("ApproveExpiringScanFolders: approved #{count} scan folders")
    count
  end
end
