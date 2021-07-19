module Jekyll
  module TallyTags

    Jekyll::Hooks.register :site, :after_init do |_|
      # 修改正则让 `2021-01-01.md` 就算无后缀也可读
      old = Jekyll::Document::DATE_FILENAME_MATCHER
      new = NO_NAME
      if old != new
        Jekyll::Document::DATE_FILENAME_MATCHER = new
      end
    end

    Jekyll::Hooks.register :site, :post_read do |site|
      Template.create(site)
    end
  end
end