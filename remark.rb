require 'mysql2'
require 'yaml'

alphabet_to_int_hash = Hash.new # アルファベットと0~25まで対応付けしたハッシュ
alphabet = 'a'
26.times {|i|
  alphabet_to_int_hash[alphabet] = i
  alphabet = alphabet.next
}
db_config = YAML.load_file('./database.yml')
client = Mysql2::Client.new(:host => db_config['host'], :username => db_config['name'], :password => db_config['pass'], :database => db_config['database'])

ARGV.each do |test_id|
  test_id = test_id.to_i
  client.query("SELECT * FROM progress INNER JOIN users ON progress.user_id = users.id WHERE test_id = #{test_id} ORDER BY test_id ASC, user_id ASC").each do |result| # 1人(1テスト)分の解答履歴
    p result['name']
    used_text = Array.new
    collect_answer = Array.new
    user_answer = Array.new
    question_ids = Array.new

    user_answer = result['list_selecter'].split(',') # ユーザの解答

    result['texts'].split(',').each {|text|
      used_text.push(alphabet_to_int_hash[text]) #問題に使われた変数を数字に変換
    }

    question_ids = result['list'].split(',')
    question_ids.each do |question_id| # 問題のidでeach
      client.query("SELECT * FROM questions WHERE id = #{question_id}").each do |question| # idから問題を抽出
        break if used_text.empty? # ユーザが答えたところまで
        collect_answer.push(question['answer'].split(',')[used_text.shift]) # 使われた変数の本当の答え
      end
    end

    begin
      user_answer.length.times {|i| # ユーザが答えたところまでアップデート
        tmp_check = user_answer[i] == collect_answer[i] ? 1 : 0
        user_answer[i] = -9999 if user_answer[i] == 'null'
        collect_answer[i] = -9999 if collect_answer[i] == 'null'

        client.query("UPDATE answers SET `answer`=#{collect_answer[i]} WHERE user_id = #{result['user_id']} AND question_id = #{question_ids[i]} AND test_flag = 1")
          puts "question_id:#{question_ids[i]} was updated."
      }
    rescue => ex
      puts ex.message
      p result['user_id']

      puts 'used_text:'
      p result['texts'] # 問題に使われた変数

      puts 'user_answer:'
      p user_answer
      p user_answer.length

      puts 'collect_answer:'
      p collect_answer
      p collect_answer.length
    end

    puts ''
  end
end
