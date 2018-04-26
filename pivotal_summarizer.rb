require 'pivotal-tracker'
require 'csv'

def put_owner_based_points(stories)
  headers = []
  result = {}
  stories.each do |s|
    month = s.accepted_at.strftime('%Y%m')
    headers << month
    result[s.owned_by] ||= {}
    result[s.owned_by][month] ||= 0
    result[s.owned_by][month] += s.estimate if s.estimate
  end

  headers.sort!.uniq!
  headers.unshift('name')

  csv = CSV.generate(headers: headers, write_headers: true) do |c|
    result.each do |owner, hash|
      h = hash.dup
      h['name'] = owner
      c << h
    end
  end
  puts csv
end

def put_story_names(stories)
  headers = ['owner', 'month', 'story', 'point']

  csv = CSV.generate(headers: headers, write_headers: true) do |c|
    stories.each do |s|
      next unless s.accepted_at > DateTime.parse('2017-04-01')
      c << {
        'owner' => s.owned_by,
        'month' => s.accepted_at.strftime('%Y%m'),
        'story' => s.name,
        'point' => s.estimate
      }
    end
  end
  File.write('story_names.csv', csv)
end

PivotalTracker::Client.token = ENV['PIVOTAL_API_TOKEN']
project = PivotalTracker::Project.find(ENV['PIVOTAL_PROJECT_ID'])
accepted_stories = project.stories.all.select { |s| s.current_state == 'accepted' }

put_owner_based_points(accepted_stories)
puts '===='
put_story_names(accepted_stories)
