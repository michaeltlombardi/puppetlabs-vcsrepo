test_name 'C3447 - checkout a tag (ssh protocol)'

# Globals
repo_name = 'testrepo_tag_checkout'
tag = '0.0.2'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup - create repo' do
    install_package(host, 'git')
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../..'))
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    on(host, "cd #{tmpdir} && ./create_git_repo.sh")
  end
  step 'setup - establish ssh keys' do
    # create ssh keys
    on(host, 'ssh-keygen -q -t rsa -f /root/.ssh/id_rsa -N ""')

    # copy public key to authorized_keys
    on(host, 'echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config')
    on(host, 'chown -R root:root /root/.ssh')
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
      apply_manifest_on(host, "file{'/root/.ssh/id_rsa': ensure => absent, force => true }")
      apply_manifest_on(host, "file{'/root/.ssh/id_rsa.pub': ensure => absent, force => true }")
  end

  step 'get tag sha from repo' do
    on(host, "git --git-dir=#{tmpdir}/testrepo.git rev-list HEAD | tail -1") do |res|
      @sha = res.stdout.chomp
    end
  end

  step 'checkout a tag with puppet' do
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "ssh://root@#{host}#{tmpdir}/testrepo.git",
      provider => git,
      revision => '#{tag}',
    }
    EOS

    apply_manifest_on(host, pp)
    apply_manifest_on(host, pp)
  end

  step "verify checkout out tag is #{tag}" do
    on(host, "ls #{tmpdir}/#{repo_name}/.git/") do |res|
      fail_test('checkout not found') unless res.stdout.include? "HEAD"
    end

    on(host,"git --git-dir=#{tmpdir}/#{repo_name}/.git name-rev HEAD") do |res|
      fail_test('tag not found') unless res.stdout.include? "#{tag}"
    end
  end

end
