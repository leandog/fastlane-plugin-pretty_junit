describe Fastlane::Actions::PrettyJunitAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The pretty_junit plugin is working!")

      Fastlane::Actions::PrettyJunitAction.run(nil)
    end
  end
end
