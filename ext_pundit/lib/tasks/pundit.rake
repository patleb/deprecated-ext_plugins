namespace :pundit do
  desc 'List policies with their actions'
  task :list => :environment do
    classes, modules = {}, {}
    (Rails::Engine.subclasses.map(&:root) << Rails.root).map do |root|
      Dir[root.join('app', 'policies', '**', '*_policy.rb')].sort.each do |file|
        policy_name = file.gsub(/^.+\/app\/policies\//, '').sub(/\.rb/, '').camelize
        policy = policy_name.constantize
        ApplicationPolicy.actions.each do |action_check|
          owner_name = policy.instance_method(action_check).owner.name
          if owner_name.end_with? 'Policy'
            classes[owner_name] ||= SortedSet.new
            classes[owner_name] << action_check.to_s
          else
            modules[owner_name] ||= SortedSet.new
            modules[owner_name] << action_check.to_s
          end
          if owner_name != policy.name
            classes[policy_name] ||= SortedSet.new
            classes[policy_name] << "< #{owner_name}"
          end
        end
      end
    end
    [classes, modules].each do |policies|
      policies.sort.each do |policy, actions|
        puts policy
        actions.each do |action_check|
          puts action_check.to_s.indent(2)
        end
      end
    end
  end
end
