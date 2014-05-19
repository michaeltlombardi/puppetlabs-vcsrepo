test_name 'C3607 - shallow clone repo depth = -1'

# Globals
repo_name = 'testrepo_shallow_clone'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup - create repo' do
    install_package(host, 'git')
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../../..'))
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    on(host, "cd #{tmpdir} && ./create_git_repo.sh")
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
  end

  step 'shallow clone repo with puppet (bad input ignored, full clone checkedout)' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "file://#{tmpdir}/testrepo.git",
      provider => git,
      depth => -1,
    }
    EOS

    apply_manifest_on(host, pp)
    apply_manifest_on(host, pp)
  end

  step 'verify checkout is NOT shallow' do
    on(host, "ls #{tmpdir}/#{repo_name}/.git/") do |res|
      fail_test('shallow not found') if res.stdout.include? "shallow"
    end
  end

end
