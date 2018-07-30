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

def summarize(project)
  puts '[start] summarize'
  accepted_stories = project.stories.all.select { |s| s.current_state == 'accepted' }.map do |s|
    s.estimate = 1 if s.estimate && s.estimate < 0
    s
  end

  put_owner_based_points(accepted_stories)
  puts '===='
  put_story_names(accepted_stories)
end

def raw(project, file_name)
  puts '[start] raw'
  stories = project.stories.all
  headers = %w(
    id name status accepted_at url
  )
  csv = CSV.generate(headers: headers, write_headers: true) do |c|
    stories.each do |s|
      c << [
        s.id,
        s.name,
        s.current_state,
        s.accepted_at,
        s.url
      ]
    end
  end
  File.write(file_name, csv)
  puts '[end] raw'
end

PivotalTracker::Client.token = ENV['PIVOTAL_API_TOKEN']
project = PivotalTracker::Project.find(ENV['PIVOTAL_PROJECT_ID'])

case ARGV[0]
when 'raw'
  file_name = ARGV[1] || 'pivotal_stories.csv'
  raw(project, file_name)
else
  summarize(project)
end
