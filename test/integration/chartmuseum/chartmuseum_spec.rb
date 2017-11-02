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
  
  http_result = http('http://0.0.0.0/index.yaml', enable_remote_worker: true)
  
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