module Jekyll
  module TallyTags
    class Template
      # @param [Array<Site>] site
      def self.create(site)
        # 首先获取所有在 `tally` 内 `list` 的值
        tally_configs = site.config.fetch(TALLY, {})
        if !(tally_configs && !tally_configs.empty?)
          return
        end
        # 然后获取默认配置 没有也是可以的
        # @type [Hash<String => Array<Integer, String>>]
        default_template = tally_configs[DEFAULT]

        if default_template
          # 初始化默认的模板
          default_template.each_key do |key|
            default_template[key] = Counter.to_array(default_template[key], nil)
          end
        end

        # 先判断有没有对应的配置
        # @type [Hash<String => Array<Integer, String>>]
        templates = tally_configs[TEMPLATES]
        # 必须有模板才可以解析
        if !(templates && !templates.empty?)
          return
        end

        # @type [Array<Document>]
        docs = site.posts.docs # 文章里的文档 (也就是 `yaml`)
        id   = 0 # id

        no_scan_docs = [] # 无法扫描的文档
        scanned_docs = [] # 创建新的文档

        # 先遍历模板
        templates.each_key do |template_key|
          template = templates[template_key].merge!(default_template)
          template.each_key do |key|
            # 依据默认模板生成新的模板
            template[key] = Counter.to_array(template[key], default_template[key])
          end
        end

        # 后便利文档
        docs.each do |doc|
          doc_date = doc.date.to_date
          # 首先假定 文档没有日期
          dates = doc.data.keys.find_all { |k| k.is_a?(Date) }
          dates.each { |date| date.to_s }
          if !dates
            dates = []
          end
          dates << doc_date

          # 判断这个文档里面有没有对应的 `template` `key`
          doc_template_keys = doc.data.keys & templates.keys
          if doc_template_keys && !doc_template_keys.empty?
            doc.data[doc_date] = {}
            doc_template_keys.each do |template_key|
              # 把数据放入列表里面
              doc.data[doc_date][template_key] = doc[template_key]
            end
          end

          dates.each do |date|
            if !doc.data[date]
              next
            end
            doc_template_keys = doc.data[date].keys

            doc_template_keys.each do |template_key|
              csv_list = doc.data[date][template_key]
              template = templates[template_key]
              # 下一步 如果 有值 且 不为空
              next unless csv_list && !csv_list.empty?

              # 如果不是数组的话
              if !csv_list.is_a?(Array)
                Jekyll.logger.warn(template_key, "#{doc.path}里的数据不为数组, 将不解析该字段")
                next
              end

              keys = template[KEYS]
              csv_list.each_index do |csv_index|
                csv = csv_list[csv_index]
                # 正则处理 把",,,"这样的 分割成" ,  ,  , "
                csv.gsub!(/[，|,|\s]+?/, " , ")
                # lstrip rstrip 去掉前后空格
                # @type [Array<String>]
                values = csv.split(',').each(&:lstrip!).each(&:rstrip!)
                # 判断有没有 `keys` 如果没有 第一行就作为 `keys` 因为第一行作为 `keys` 就是像极了 `csv`
                if (!template[KEYS] || template[KEYS].empty?) && csv_index == 0
                  keys = values
                  next
                end
                # 针对 `values` 补充一个日期到最末尾

                # 初始化数据
                Date.new
                datum = {
                  ID        => id,
                  PERMALINK => "/#{ID}/#{id}",
                  DATE      => date.to_time,
                  TEMPLATE  => template_key,
                  SLUG      => date.to_s,
                  KEYS      => keys,
                  VALUES    => values,
                  LAYOUT    => 'default',
                  # CONTENT   => self.doc_to_yml(date.to_s, template_key, keys, values)
                  # CONTENT   => docs_to_yml()
                }
                # 对当前 `template` 所有 `key` 遍历
                template.each_key do |key|
                  datum[key] = Counter.formatValues(values, template[key])
                end

                # 对 `values` 所有 内容 遍历
                values.each_index do |index|
                  datum[keys[index]] = values[index]
                end

                new_doc = Item.new(doc, site, datum)
                scanned_docs << new_doc
                id += 1
              end
            end
          end
        end
        # @type [Array<Document>]
        all_docs = no_scan_docs + scanned_docs
        # 判断是不是需要 开启组合模式
        combine_configs = tally_configs[COMBINE]
        if combine_configs && combine_configs.is_a?(Array)
          combine_configs.each do |config|
            find_key      = config[FIND]
            combine_key   = config[TO]
            deep_key      = config[DEEP]
            all_find_keys = []
            all_docs.each do |doc|
              if doc.data[find_key]
                # 找到所有 `key`
                all_find_keys += doc.data[find_key]
              end
            end
            all_find_keys.uniq!
            if all_find_keys.size >= 2
              all_docs.each do |doc|
                # 初始化
                doc.data[combine_key] = []
              end
              merges = Counter.merge_all(all_find_keys, deep_key)
              Counter.combine_merge_list(merges, all_docs, find_key, combine_key)
            end
          end
        end

        site.posts.docs = all_docs
      end

      # @param [Array<Document>] docs
      def self.docs_to_yml(docs)

        yaml_mode     = false
        md_table_mode = false

        # 获取里面所有的 `template keys`
        template_keys = docs.collect() { |doc| doc.data[TEMPLATE] }.uniq
        align         = yaml_mode ? "" : ":----:"
        sep           = yaml_mode ? " " : " | "
        # 初始化

        yaml_templates_hash = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = { VALUES_LIST => [] } } }
        template_keys.each do |template_key|
          # 找到当前遍历的 符合 `key` 的所有 `docs`
          template_docs = docs.find_all() { |doc| doc.data[TEMPLATE] == template_key }
          template_docs.each do |doc|
            keys = [DATE_TITLE] + doc.data[KEYS]
            yaml_templates_hash[template_key][keys][VALUES_LIST] << [doc.data[SLUG]] + doc.data[VALUES]
          end
          # 计算 对齐空格数
          yaml_templates_hash[template_key].each_key do |keys|
            values_list = yaml_templates_hash[template_key][keys][VALUES_LIST]
            lengths     = []
            keys.each_index do |index|
              k_length       = get_length(keys[index])
              v_max          = values_list.collect() { |values| values[index] }.max_by() { |value| get_length(value) }
              lengths[index] = [k_length, get_length(v_max), get_length(align)].max()
            end
            yaml_templates_hash[template_key][keys][MAX_LENGTH] = lengths
          end
        end

        content = ""
        if yaml_mode
          content += "```yml\n"
          yaml_templates_hash.each_key do |template_key|
            content        += "#{template_key}:\n"
            templates_hash = yaml_templates_hash[template_key]
            templates_hash.each_key do |keys|
              hash    = templates_hash[keys]
              lengths = hash[MAX_LENGTH]
              content += "  - #{center_values(keys, lengths, sep)}\n"
              hash[VALUES_LIST].each_index do |index|
                values  = hash[VALUES_LIST][index]
                content += "  - #{center_values(values, lengths, sep)}\n"
              end
              content += "\n"
            end
            content += "\n"
          end
          content += "```"
        else
          content += "```markdown\n" if md_table_mode
          yaml_templates_hash.each_key do |template_key|
            templates_hash = yaml_templates_hash[template_key]
            templates_hash.each_key do |keys|
              hash    = templates_hash[keys]
              lengths = hash[MAX_LENGTH]
              content += "#{sep}#{center_values(keys, lengths, sep)}#{sep}\n"
              content += "#{sep}#{center_values(keys.map { align }, lengths, sep)}#{sep}\n"
              hash[VALUES_LIST].each_index do |index|
                values  = hash[VALUES_LIST][index]
                content += "#{sep}#{center_values(values, lengths, sep)}#{sep}\n"
              end
              content += "\n"
            end
            content += "\n"
          end
          content += "```" if md_table_mode
        end
        content
      end

      # @param [Array<String>] values
      # @param [Array<Int>] lengths
      # @param [String] sep
      def self.center_values(values, lengths, sep)
        temp = Array.new(values)
        temp.each_index do |index|
          # ljust center rjust
          temp[index] = temp[index].encode('gbk').b.center(lengths[index]).force_encoding("gbk").encode("utf-8")
        end
        temp.join(sep)
      end

      # @param [String] value
      def self.get_length(value)
        value.encode('gbk').b.length
      end

      def self.append_date(values, date)
        Array.new(values).insert(0, date)
      end
    end
  end
end

