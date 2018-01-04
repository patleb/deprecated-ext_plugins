module SunCap
  module AuthorizedKeys
    def build_authorized_keys
      keys =
        if SettingsYml[:authorized_keys]
          SettingsYml[:authorized_keys].join("\\n")
        else
          SettingsYml[:deployer_public_key]
        end
      raise ':authorized_keys or :deployer_public_key must be defined' unless keys.present?

      "echo -e '#{keys}' > /home/deployer/.ssh/authorized_keys"
    end
  end
end
