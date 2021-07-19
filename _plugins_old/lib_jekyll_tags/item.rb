require 'jekyll'

module Jekyll
  module TallyTags
    class Item < Jekyll::Document

      # @param [Document] doc
      # @param [Site] site
      # @param [Hash] datum
      def initialize(doc, site, datum)
        path        = doc.path
        @data       = Hash.new(doc.data)
        @data[DATA] = {}
        datum.each_key do |key|
          @data[key]       = datum[key]
          @data[DATA][key] = datum[key]
        end
        self.content = Template.docs_to_yml([self])

        @site       = site
        @path       = path
        @extname    = File.extname(path)
        @collection = site.posts
        @type       = @collection.label.to_sym

        # 获取配置
        @tally_config = site.config.fetch(TALLY, {})
        @gen_config = site.config.fetch(CLASSIFY, {})

        @has_yaml_header = nil

        if draft?
          categories_from_path("_drafts")
        else
          categories_from_path(collection.relative_directory)
        end

        data.default_proc = proc do |_, key|
          site.frontmatter_defaults.find(relative_path, type, key)
        end
      end

    end
  end
end
