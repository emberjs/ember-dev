require 'pathname'
require 'fileutils'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "spec"
  t.test_files = FileList['spec/**/*_spec.rb']
end

task :clear_test_repos do
  FileUtils.rm_rf 'spec/support/test_repos'
end

task :setup_test_repos => :clear_test_repos do
  repo_base_path = Pathname.new('spec/support/test_repos').expand_path
  abort 'Repos already setup' if repo_base_path.exist?

  FileUtils.mkdir_p repo_base_path.to_s
  Dir.chdir repo_base_path.realpath
  sh('mkdir standard_repo')
  Dir.chdir repo_base_path.join('standard_repo').realpath
  sh('git init .')
  sh('touch blahzorz')
  sh('git config user.email "test@example.com"')
  sh('git config user.name "Test User"')
  sh('git add blahzorz')
  sh('git commit -m "Added blahzorz."')
  sh('touch blammo')
  sh('git add blammo')
  sh('git commit -m "Added blammo."')
  sh('git tag rubble')

  Dir.chdir repo_base_path
  sh('cp -r standard_repo standard_repo_on_branch')

  Dir.chdir repo_base_path.join('standard_repo_on_branch').realpath
  sh('git checkout -b barney')
  sh('touch wilma')
  sh('git add wilma')
  sh('git commit -m "Add wilma."')
end

task :default => ['setup_test_repos', 'test']
