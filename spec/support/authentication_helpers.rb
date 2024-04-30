module AuthenticationHelpers
  def login_as(user)
    warden_double = instance_double(Warden::Proxy,
                                    authenticated?: true,
                                    authenticate!: true,
                                    user:)
    allow_any_instance_of(ApplicationController) # rubocop:disable RSpec/AnyInstance
      .to receive(:warden)
      .and_return(warden_double)
  end
end
