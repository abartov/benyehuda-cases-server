module ScanFoldersHelper
  UNIT_KEYS = %w[byte kb mb gb tb].freeze

  # Like number_to_human_size, but with units from scans.size_units, which are not shadowed by the
  # gettext DB translations of number.human.storage_units.
  def scan_size(bytes)
    bytes = bytes.to_i
    return "#{bytes} #{t('scans.size_units.byte', count: bytes)}" if bytes < 1024

    exp = [(Math.log(bytes) / Math.log(1024)).to_i, UNIT_KEYS.size - 1].min
    value = (bytes / (1024.0**exp)).round(2)
    "#{value.to_s.sub(/\.0\z/, '')} #{t("scans.size_units.#{UNIT_KEYS[exp]}")}"
  end
end
