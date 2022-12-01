
Authority.destroy_all

Authority.create!([
  {
    name: "localhost Domain",
    domain: "http://localhost/",
    description: "used for testing"
  }
])

puts "Created #{Authority.count} Authority"
