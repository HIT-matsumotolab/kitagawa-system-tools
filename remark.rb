require 'mysql2'

test_id = 11

alphabet_to_int_hash = Hash.new # アルファベットと0~25まで対応付けしたハッシュ
alphabet = 'a'
26.times {|i|
  alphabet_to_int_hash[alphabet] = i
  alphabet = alphabet.next
}

client = Mysql2::Client.new(:host => 'localhost', :username => 'root', :password => 'root', :database => 'c_training4')
client.query("SELECT * FROM progress INNER JOIN users ON progress.user_id = users.id WHERE test_id = #{test_id} ORDER BY test_id ASC, user_id ASC").each do |result| # 1人(1テスト)分の解答履歴
  used_text = Array.new
  # p result['user_id']
  p result['list_selecter'] # ユーザの解答
  p result['texts'] # 問題に使われた変数

  result['texts'].split(',').each {|text|
    used_text.push(alphabet_to_int_hash[text]) #問題に使われた変数を数字に変換
  }
  p used_text

  result['list'].split(',').each do |question_id| # 問題のidでeach
    client.query("SELECT * FROM questions WHERE id = #{question_id}").each do |question| # idから問題を抽出
      break if used_text.empty? # ユーザが答えたところまで
      p question['answer'].split(',')[used_text.shift] # 使われた変数の本当の答え
    end
  end
end