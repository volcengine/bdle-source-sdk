Pod::Spec.new do |s|
  s.name             = 'BDLESource'
  s.version          = '1.0.0'
  s.summary          = 'BDLE Source SDK'
  s.description      = 'BDLE Source SDK.'
  s.homepage         = 'https://github.com/bdle/BDLE'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wangwenlong.8' => 'wangwenlong.8@bytedance.com' }
  s.source           = { :git => 'git@github.com:bdle/BDLE.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.default_subspec  = 'Default'
  s.requires_arc     = true

  s.subspec 'Utils' do |utils|
    utils.source_files = 'Utils/**/*.{h,m,mm}'
  end  

  s.subspec 'UPnP' do |upnp|
    upnp.source_files = 'UPnP/**/*.{h,m,mm}'
    upnp.subspec 'Nonarc' do |nonarc|
      nonarc.requires_arc = false
      nonarc.ios.libraries = 'xml2'
      nonarc.source_files = 'UPnP/Nonarc/*.{h,m,mm}'
      nonarc.xcconfig = {'HEADER_SEARCH_PATHS' => '${SDKROOT}/usr/include/libxml2'}
      nonarc.private_header_files = 'UPnP/Nonarc/*.h'
    end
    upnp.dependency 'CocoaAsyncSocket'
    upnp.dependency 'BDLESource/Utils'
  end

  s.subspec 'Impl' do |impl|
    impl.source_files = 'Impl/**/*.{h,m,mm}'
    impl.dependency 'YYModel'
    impl.dependency 'CocoaAsyncSocket'
    impl.dependency 'BDLESource/Utils'
    impl.dependency 'BDLESource/UPnP'
  end

  s.subspec 'Default' do |default|
    default.dependency 'BDLESource/Utils'
    default.dependency 'BDLESource/UPnP'
    default.dependency 'BDLESource/Impl'
  end

  
end
