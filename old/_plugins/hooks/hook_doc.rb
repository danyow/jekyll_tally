module Jekyll

  class Counter
    def self.get_value(array, idx, default)
      return default unless array

      if array.size == 1 && idx >= 1
        array[0]
      elsif idx > array.size - 1
        default
      else
        array[idx]
      end
    end

    def self.to_string(hash, format)
      hash.each do |key, value|
        hash[key] = to_f_s(value, format)
      end
    end

    def self.to_f_s(number, format)
      if number - number.round != 0
        format % number.round(2).to_s
      else
        format % number.round.to_s
      end
    end

    def self.double_f_s(format, a, b)
      a = Counter.to_f_s(a, "%s")
      b = Counter.to_f_s(b, "%s")
      format % [a, b]
    end

    def self.formats(item, formats)
      results = []
      formats.each do |format|
        # indexes = /((?<=:)\d)+/.match(format).to_a
        matches = format.scan(/(?<=:)\d/)
        indexes = []
        matches.each do |match|
          indexes << (item[match.to_i]).to_s
        end
        matches = format.scan(/:\d/)
        id = 0
        result = format
        matches.each do |match|
          result = result.gsub(match, indexes[id])
          id += 1
        end
        results << result
      end
      results
    end
  end

  DATE_FILENAME_MATCHER = %r!^(?>.+/)*?(\d{2,4}-\d{1,2}-\d{1,2})(-([^/]*))?(\.[^.]+)$!.freeze

  Jekyll::Hooks.register :site, :after_init do |data|
    # 修改正则让 `2021-01-01.md` 就算无后缀也可读
    Jekyll::Document::DATE_FILENAME_MATCHER = DATE_FILENAME_MATCHER
  end

  Jekyll::Hooks.register :site, :post_read do |site|

    CR = 'counter'.freeze # 总配置字段
    LT = 'list'.freeze # 对应的 key 表
    UT = 'unit'.freeze # 表内 计算后的单位
    NE = 'name'.freeze # key 表的名称
    CT = 'count'.freeze # 需要计算的下标
    CY = 'category'.freeze # 分类下标
    TG = 'tag'.freeze # 标签下标
    TS = 'tags'.freeze # 需要分类的下标
    FS = 'formats'.freeze # 需要格式化的下标
    AE = 'average'.freeze # 需要人均的下标
    AT = 'avg_unit'.freeze # 需要人均的下标
    NR = 'number'.freeze # 需要总数的下标
    NT = 'num_unit'.freeze # 需要总数的下标
    XK = 'all'.freeze # all all all
    XN = '全部'.freeze # all all all
    XX = '(%s)'.freeze # all

    YR = 'year'.freeze
    MH = 'month'.freeze
    DY = 'day'.freeze

    # 首先获取所有在 `counter` 内 `list` 的值
    c_config = site.config.fetch(CR, {})
    unit = c_config[UT]

    posts = site.collections['posts'] # 文章集合
    docs = posts.docs # 文章里的文档 (也就是yaml)

    x_all = 0.0
    x_y_all = {} # 年
    x_m_all = {} # 月
    x_d_all = {} # 日
    x_t_all = {} # 二维数组
    new_docs = [] # 创建新的文档
    x_id = 0
    # 开始遍历
    c_config[LT].each do |key|
      # 从配置里面取出 对应配置
      config = site.config.fetch(key, {})
      # 获取 配置
      c_idx = config[CT]
      name = config[NE]
      c_unit = config[UT] ? config[UT] : unit
      a_unit = config[AT]
      n_unit = config[NT]
      tags_ids = config[TS]
      format_ids = config[FS]
      a_idx = config[AE]
      n_idx = config[NR]

      k_all = 0.0 # 累计计数
      y_all = {} # 年
      m_all = {} # 月
      d_all = {} # 日
      t_all = {} # 二维数组

      pre_item = []

      docs.each do |doc|
        date = doc.data.include?('date') ? doc.data['date'] : doc.basename_without_ext
        days = date.strftime('%Y/%m/%d')
        mont = date.strftime('%Y/%m')
        year = date.strftime('%Y')

        contents = doc.data[key]
        # 下一步 如果 books 有值 且 不为空
        next unless contents && !contents.empty?
        # 就开始遍历
        id = 0
        keys = []
        contents.each do |content|
          # 正则处理 把",,,"这样的 分割成" ,  ,  , "
          content.gsub!(/[，|,]/, " , ")
          # lstrip 去掉前后空格
          item = content.split(',').each(&:lstrip!).each(&:rstrip!)
          if id == 0
            id += 1
            #  跳出本次循环
            keys = item
            next
          end

          new_item = {}
          x_item = {}
          # 获取需要统计的数值
          cnt = item[c_idx]

          # 初始化第一个数据
          d_all[days] = 0.0 unless d_all.include?(days)
          m_all[mont] = 0.0 unless m_all.include?(mont)
          y_all[year] = 0.0 unless y_all.include?(year)
          x_d_all[days] = 0.0 unless x_d_all.include?(days)
          x_m_all[mont] = 0.0 unless x_m_all.include?(mont)
          x_y_all[year] = 0.0 unless x_y_all.include?(year)

          # 转为两位小数
          cnt_to_f = cnt.to_f.round(2)
          # 叠加
          d_all[days] += cnt_to_f
          m_all[mont] += cnt_to_f
          y_all[year] += cnt_to_f
          k_all += cnt_to_f
          x_d_all[days] += cnt_to_f
          x_m_all[mont] += cnt_to_f
          x_y_all[year] += cnt_to_f
          x_all += cnt_to_f

          index = 0
          tags = []
          x_tags = []
          item.each do |value|
            # 这个 item 可能是空的
            if value.empty? && !pre_item[index].empty?
              value = pre_item[index]
              item[index] = value
            end
            if value.empty?
              value = "null"
              item[index] = value
            end
            # 判断有没有遍历到对应的下标
            if tags_ids.include?(index)
              tags << value
              x_tags << "#{XX}" % "#{value}"
              # 初始化数值
              t_all[value] = 0.0 unless t_all.include?(value)
              t_all[value] += cnt_to_f
              x_t_all["#{XX}" % "#{value}"] = 0.0 unless x_t_all.include?(value)
              x_t_all["#{XX}" % "#{value}"] += cnt_to_f
            end
            new_item[keys[index]] = value
            x_item[keys[index]] = value
            # 对人均数和总数计算
            if a_idx && index == a_idx
              avg = value.to_i
              new_item[keys[index]] = Counter.to_f_s(cnt_to_f / avg, a_unit)
              x_item[keys[index]] = Counter.to_f_s(cnt_to_f / avg, a_unit)
            end
            if n_idx && index == n_idx
              num = value.to_i
              new_item[keys[index]] = Counter.double_f_s(n_unit, cnt_to_f / num, num)
              x_item[keys[index]] = Counter.double_f_s(n_unit, cnt_to_f / num, num)
            end
            index += 1
          end

          # 对格式化进行处理
          if format_ids
            formats = Counter.formats(item, format_ids)
            # 把格式化过的 formats 填充到 tags 内
            tags = tags + formats
            x_formats = Counter.formats(item, format_ids)
            x_formats.collect! { |f| "#{XX}" % "#{f}" }
            x_tags = x_tags + x_formats
          end

          pre_item = item

          new_item['id'] = id
          new_item['which'] = key
          new_item[FS] = formats

          # 可能会死循环 `Document.new` 还会发消息
          new_doc = Document.new(doc.path, site: site, collection: posts)
          new_doc.data.replace(doc.data)
          # 重新赋值
          new_doc.data['data'] = new_item
          new_doc.data['categories'] = [key]
          new_doc.data['which'] = name
          new_doc.data['tags'] = tags
          new_doc.data['title'] = Counter.to_f_s(cnt_to_f, c_unit)
          new_doc.data['excerpt'] = item[3]
          new_doc.data['permalink'] = "/#{key}/:year/:month/:day/#{id}/"
          new_doc.content = key
          new_docs << new_doc

          # 来多一份 用来统计全部的
          x_item['id'] = x_id
          x_item['which'] = XK
          x_item[FS] = formats
          cut_doc = Document.new(doc.path, site: site, collection: posts)
          cut_doc.data.replace(doc.data)
          # 重新赋值
          cut_doc.data['data'] = x_item
          cut_doc.data['categories'] = [XK]
          cut_doc.data['which'] = XN
          cut_doc.data['tags'] = x_tags
          cut_doc.data['title'] = Counter.to_f_s(cnt_to_f, c_unit)
          cut_doc.data['excerpt'] = item[3]
          cut_doc.data['permalink'] = "/#{XK}/:year/:month/:day/#{x_id}/"
          cut_doc.content = XN
          new_docs << cut_doc

          id += 1
          x_id += 1
        end
      end
      Counter.to_string(d_all, c_unit)
      Counter.to_string(m_all, c_unit)
      Counter.to_string(y_all, c_unit)

      t_all.each do |k, v|
        t_all[k] = Counter.to_f_s(v, c_unit)
      end

      site.data[CR] = {} unless site.data.include?(CR)
      site.data[CR][LT] = {} unless site.data[CR].include?(LT)
      site.data[CR][LT][key] = {
        key => name,
        YR => y_all,
        MH => m_all,
        DY => d_all,
        TG => t_all,
        CY => Counter.to_f_s(k_all, c_unit),
        CT => Counter.to_f_s(k_all, c_unit)
      }
    end
    Counter.to_string(x_d_all, unit)
    Counter.to_string(x_m_all, unit)
    Counter.to_string(x_y_all, unit)

    x_t_all.each do |k, v|
      x_t_all[k] = Counter.to_f_s(v, unit)
    end

    site.data[CR] = {} unless site.data.include?(CR)
    site.data[CR][LT] = {} unless site.data[CR].include?(LT)
    site.data[CR][LT][XK] = {
      XK => XN,
      YR => x_y_all,
      MH => x_m_all,
      DY => x_d_all,
      TG => x_t_all,
      CY => Counter.to_f_s(x_all, unit),
      CT => Counter.to_f_s(x_all, unit)
    }
    if new_docs.size != 0
      posts.docs = new_docs
    end
    site.data[CR][CT] = Counter.to_f_s(x_all, unit)
  end
end
