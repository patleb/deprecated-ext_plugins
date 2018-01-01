require 'rails_helper'

describe Setting do
  it { is_expected.to have_db_column(:name).of_type(:string) }
  it { is_expected.to have_db_column(:value).of_type(:text) }
  it { is_expected.to have_db_column(:unit).of_type(:string) }
  it { is_expected.to have_db_column(:history).of_type(:text).with_options(array: true, default: []) }
  it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  it { is_expected.to have_db_index(:name).unique(true) }
  it { is_expected.to have_db_index(:history) }
  it { is_expected.to callback(:update_history).before(:update) }

  describe '.yaml' do
    it 'should load app and engines settings.yml' do
      expect(Setting[:email_address]).to eq('test@example.com')
      expect(Setting[:engine_name]).to eq('dev_set_thing')
    end
  end

  context 'with settings table filled' do
    fixtures :settings

    describe '.[]' do
      it 'should find the setting from settings table' do
        expect(Setting[:simple]).to eq('with value')
      end

      it 'should find the setting from config/settings.yml only' do
        expect(Setting[:email_address]).to eq('test@example.com')
      end

      it 'should not find the setting' do
        expect{ Setting[:not_found] }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '.[]=' do
      it 'should find the setting and change its value' do
        Setting[:simple] = 'any other value'

        expect(Setting[:simple]).to eq('any other value')
      end

      it 'should create the setting' do
        Setting[:new_setting] = 'any value'

        expect(Setting[:new_setting]).to eq('any value')
      end
    end

    describe '.rename!' do
      it 'should rename the setting' do
        Setting.rename! :simple, :new_simple

        expect{ Setting[:simple] }.to raise_error(ActiveRecord::RecordNotFound)
        expect(Setting[:new_simple]).to eq('with value')
      end
    end

    describe '.modify!' do
      it 'should modify the setting' do
        Setting.modify! :simple, 'new value'

        expect(Setting[:simple]).to eq('new value')
      end
    end

    describe '.migration_apply_all' do
      it 'should create settings' do
        Setting.migration_apply_all(
          setting_one: 'value 1',
          setting_two: ['100', 'meters'],
        )

        expect(Setting[:setting_one]).to eq('value 1')
        setting_two = Setting.find_by(name: 'setting_two')
        expect(setting_two.value).to eq('100')
        expect(setting_two.unit).to eq('meters')
      end
    end

    describe '.migration_modify_all' do
      it 'should modify settings' do
        Setting.migration_modify_all(
          simple: 'new value',
          email_address: ['new@address.com', 'changed']
        )

        expect(Setting[:simple]).to eq('new value')
        setting_two = Setting.find_by(name: 'email_address')
        expect(setting_two.value).to eq('new@address.com')
        expect(setting_two.unit).to eq('changed')
      end
    end

    describe '.migration_remove_all' do
      it 'should remove settings' do
        Setting.migration_remove_all(
          :email_single,
          :email_list,
        )

        expect{ Setting[:email_single] }.to raise_error(ActiveRecord::RecordNotFound)
        expect{ Setting[:email_list] }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '.cast' do
      it 'should cast booleans' do
        expect(Setting.cast(:boolean_true, :bool)).to eq(true)
        expect(Setting.cast(:boolean_false, :boolean)).to eq(false)
      end

      it 'should cast emails' do
        expect(Setting.cast(:email_single, :emails).size).to eq(1)
        expect(Setting.cast(:email_list, :emails).size).to eq(4)
      end

      it 'should cast durations' do
        expect(Setting.cast(:duration_normal, :seconds)).to eq(270)
        expect(Setting.cast(:duration_normal, :duration)).to eq(270)
        expect(Setting.cast(:duration_empty, :duration)).to eq(0)
        expect(Setting.cast(:duration_nil, :duration)).to eq(0)
        expect(Setting.cast(:duration_corrupted, :duration)).to eq(0)
        expect(Setting.cast(:duration_zero, :duration)).to eq(0)
      end

      it 'should not cast if not supported' do
        expect(Setting.cast(:simple, :not_supported_type)).to be_kind_of(String)
      end
    end

    describe '.history and #history' do
      it 'should have empty history when created' do
        expect(Setting.history(:simple)).to eq([])
      end

      it 'should have history after update' do
        Setting.modify! :simple, 'new value'
        Setting.modify! :simple, 'new new value'

        expect(Setting.history(:simple).map(&:value)).to eq(['new value', 'with value'])
      end
    end
  end
end
