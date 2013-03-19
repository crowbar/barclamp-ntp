Rails.application.routes.draw do

  mount BarclampNtp::Engine => "/barclamp_ntp"
end
