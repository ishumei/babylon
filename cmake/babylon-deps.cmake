if(NOT TARGET absl::base)
  find_package(absl REQUIRED)
endif()

if(TARGET Boost::boost)
elseif(TARGET Boost::preprocessor AND TARGET Boost::spirit)
else()
  find_package(Boost REQUIRED)
endif()
