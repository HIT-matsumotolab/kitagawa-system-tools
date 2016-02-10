require 'mysql2'
require "csv"
class OutputFromProgress

  def initialize()
    @client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "root", :database => "c_training5")
    @alphabet_to_int_hash = Hash.new # アルファベットと0~25まで対応付けしたハッシュ
    alphabet = 'a'
    26.times {|i|
      @alphabet_to_int_hash[alphabet] = i
      alphabet = alphabet.next
    }
    @output_hash = Hash.new
    get_users
  end

  def get_users
    @client.query("SELECT name FROM users WHERE `name` LIKE 'b21%'").each do |user|
      @output_hash[user['name']] = ''
    end
  end

  def export_collect_flags(test_id, date)
    # list, list_selecter, list_answer
    output_array = Array.new
    user_answer_array = Array.new
    sorted_question_ids = Array.new

    @client.query("SELECT * FROM progress INNER JOIN users ON progress.user_id = users.id WHERE test_id = #{test_id} ORDER BY test_id ASC, user_id ASC").each do |list|
      puts "user_name:" + list['name'].to_s + ", user_id:" + list['user_id'].to_s
      questions_list = list['list'].split(',')
      sorted_question_ids = questions_list.sort
      list_selector_array = list['list_selecter'].split(',')
      list_answer_array = list['list_answer'].split(',')
      texts_array = list['texts'].split(',')

      collect_flags = Array.new
      for i in 0 ... list_selector_array.length
        @client.query("SELECT * FROM questions WHERE id = #{questions_list[i].to_i}").each do |question| # idから問題を抽出
          begin
            tmp_answer_index = @alphabet_to_int_hash[texts_array[i]]
            list_selector_array[i] = question['answer'].split(',')[tmp_answer_index] # 使われた変数の本当の答え
          rescue => ex
            puts ex.message
            p i
            p questions_list
            p list_selector_array
            p list_answer_array
            p texts_array
            p question['answer'].split(',')
          end
        end
        if list_answer_array[i] == list_selector_array[i]
          collect_flags.push(1)
        else
          collect_flags.push(0)
        end
      end

      # question_id => collect_flagになるハッシュ
      id_collect_hash = Hash.new
      id_user_answer_hash = Hash.new
      questions_list.each { |ql|
        id_collect_hash[ql] = collect_flags.shift
        id_user_answer_hash[ql] = list_answer_array.shift
      }
      id_collect_hash = id_collect_hash.sort
      id_user_answer_hash = id_user_answer_hash.sort

      id_collect_hash.each do |op|
        @output_hash[list['name']] += op[1].to_s + ','
      end

      tmp_user_answer_ary = Array.new
      tmp_user_answer_ary.push(list['name'])
      id_user_answer_hash.each do |op|
        tmp_user_answer_ary.push(op[1])
      end
      user_answer_array.push(tmp_user_answer_ary)
    end

    p @output_hash.to_a

    CSV.open("./tmp/#{date}_collect_flags.csv", "w") do |csv|
      sorted_question_ids.unshift('')
      csv << sorted_question_ids
      @output_hash.to_a.each do |arr|
        arr[1] = arr[1].split(',').map{|a|
          if a == ''
            -1
          else
            a.to_i
          end
        }
        p arr.flatten!
        csv << arr
      end
    end
    CSV.open("./tmp/#{date}_user_answers.csv", "w") do |csv|
      csv << sorted_question_ids
      user_answer_array.each do |arr|
        csv << arr
      end
    end
  end

  def export_question_answers(test_id, date)
    output = Array.new
    question_ids = Array.new
    # @client.eachにしてるけど1つしか存在しないので1回しか回らない
    @client.query("SELECT list FROM progress INNER JOIN users ON progress.user_id = users.id WHERE test_id = #{test_id} ORDER BY test_id ASC, user_id ASC LIMIT 1").each do |list|
      # puts "question_ids:" + list['list'].to_s
      question_ids = list['list'].split(',').sort
    end

    question_ids.each do |question_id|
      # @client.eachにしてるけど1つしか存在しないので1回しか回らない
      @client.query("SELECT answer FROM questions WHERE id = #{question_id}").each do |answer|
        tmp = answer['answer'].split(',')
        # p tmp
        tmp.unshift(question_id.to_i)
        output.push(tmp)
      end
    end

    CSV.open("./tmp/#{date}_question_answers.csv", "w") do |csv|
      tmp = 'a'
      tmp_array = Array.new([" "])
      10.times {
        tmp_array.push(tmp)
        tmp = tmp.succ
      }
      csv << tmp_array
      output.each do |arr|
        csv << arr
      end
    end
  end

  def export_user_answers(test_id, date)

  end
end

tr = OutputFromProgress.new
a = Hash.new

a['11'] = 20150930
# a['12'] = 20151002
# a['13'] = 20151007
# a['14'] = 20151009
# a['15'] = 20151014
# a['16'] = 20151016
# a['17'] = 20151021
# a['18'] = 20151023
# a['19'] = 20151028
# a['20'] = 20151030
# a['21'] = 20151104
# a['22'] = 20151111
# a['23'] = 20151113
# a['24'] = 20151125
# a['25'] = 20151127
# a['26'] = 20151202
# a['27'] = 20151204
# a['28'] = 20151209
# a['29'] = 20151211
# a['30'] = 20151216
# a['31'] = 20151216
# a['32'] = 20151218
# a['33'] = 20150106
# a['34'] = 20150108
# a['35'] = 20150113
# a['36'] = 20150115
a.each do |key, val|
  tr.export_collect_flags(key, val)
  tr.export_question_answers(key, val)
end
# tr.export_user_answers(18, 20151023)