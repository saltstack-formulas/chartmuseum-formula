# encoding: utf-8

control 'Docker container' do
  title 'Verify chartmuseum docker container'
  desc 'Ensures chartmuseum container is running as expected'
  describe docker_container('chartmuseum') do
    it { should exist }
    it { should be_running }
    its('id') { should_not eq '' }
    its('repo') { should eq 'chartmuseum/chartmuseum' }
    its('tag') { should eq 'latest' }
    its('ports') { should eq '0.0.0.0:80->8080/tcp' }
  end
end

control 'Chartmuseum service' do
  title 'Verify Chartmuseum service'
  desc 'Ensures Chartmuseum service is accessible'

  #
  # Retrieve the IP for the docker host, since Chartmuseum will be bound and
  # exposed on the docker host. For example:
  # 
  # docker host: 172.17.0.1
  # Kitchen container: 172.17.0.2
  # CHartmuseum container: 172.17.0.3
  # 
  # Chartmuseum will be bound and exposed on the docker host (172.17.0.1), not 
  # the Kitchen container.
  #
  def get_docker_host_ip()
    cmd_result = command("docker network inspect --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}' bridge")
    return cmd_result.stdout.strip()
  end

  host_ip = get_docker_host_ip()
  http_result = http("http://#{host_ip}/index.yaml", enable_remote_worker: true)
  
  describe http_result do
    its('status') { should cmp 200 }
    its('headers.Content-Type') { should cmp 'application/x-yaml' }
  end

  if http_result.body
    describe yaml({ content: """#{http_result.body}""" }) do
      its('apiVersion') { should eq('v1') }
      its(['entries', 'mailhog']) { should_not cmp nil }
      its(['entries', 'mailhog', 0, 'urls', 0]) { should match /^http:\/\/0.0.0.0/ }
      its(['entries', 'redmine']) { should_not cmp nil }
      its(['entries', 'redmine', 0, 'urls', 0]) { should match /^http:\/\/0.0.0.0/ }
    end
  end

end