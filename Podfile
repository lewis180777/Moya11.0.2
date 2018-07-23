# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'


project 'Moya11.0.2.xcodeproj'

# Uncomment the next line to define a global platform for your project

source 'https://github.com/CocoaPods/Specs.git' 

inhibit_all_warnings!
platform :ios,’8.0’

def shared_pods


    pod 'Moya'
    pod 'Moya/RxSwift'
    pod 'Moya/ReactiveSwift'
    


end



target 'Moya11.0.2' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  shared_pods
 

  target 'Moya11.0.2Tests' do
    inherit! :search_paths
    
  end

  target 'Moya11.0.2UITests' do
    inherit! :search_paths
   
  end

end
