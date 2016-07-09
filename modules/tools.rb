module KekBot
  def save
    $db['timestamp'] = Time.now.to_s
    file = File.open("kekdb.json", "w")
    file.write(JSON.pretty_generate($db))
  end

  def getCollectible(description)
    $db['collectibles'].each do |id, data|
      return { "id" => id, "data" => data } if data['description'] == description
    end
    return nil
  end

  def parse(seperator, input)
    input = input.prepend("#{seperator}default ")
    output = Hash.new
    input.split(seperator).drop(1).map do |x|
      x = x.split(' ')
      arg = x.shift
      puts content = x.join(' ')
      output[arg] = content
    end
    return output
  end
end
