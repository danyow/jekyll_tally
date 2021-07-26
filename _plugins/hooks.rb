module Jekyll
  module Tally
    DEBUG = false
    Jekyll::Hooks.register :site, :after_init do |_|
      puts 'site   after_init 在网站初始化时，但是在设置和渲染之前，适合用来修改网站的配置项' if DEBUG
      # 修改正则让 `2021-01-01.md` 就算无后缀也可读
      Jekyll::Document::DATE_FILENAME_MATCHER = NO_NAME
    end
    Jekyll::Hooks.register :site, :post_read do |site|
      puts 'site   post_read 在网站数据从磁盘中读取并加载之后' if DEBUG
      DocsToItems.read(site)
    end

    Jekyll::Hooks.register :site, :after_reset do |_|
      puts 'site   after_reset 网站重置之后' if DEBUG
    end
    Jekyll::Hooks.register :site, :pre_render do |_|
      puts 'site   pre_render 在渲染整个网站之前' if DEBUG
    end
    Jekyll::Hooks.register :site, :post_render do |_|
      puts 'site   post_render 在渲染整个网站之后，但是在写入任何文件之前' if DEBUG
    end
    Jekyll::Hooks.register :site, :post_write do |_|
      puts 'site   post_write 在将整个网站写入磁盘之后' if DEBUG
    end
    Jekyll::Hooks.register :pages, :post_init do |_|
      puts 'pages   post_init 每次页面被初始化的时候' if DEBUG
    end
    Jekyll::Hooks.register :pages, :pre_render do |_|
      puts 'pages   pre_render 在渲染页面之前' if DEBUG
    end
    Jekyll::Hooks.register :pages, :post_render do |_|
      puts 'pages   post_render 在页面渲染之后，但是在页面写入磁盘之前' if DEBUG
    end
    Jekyll::Hooks.register :pages, :post_write do |_|
      puts 'pages   post_write 在页面写入磁盘之后' if DEBUG
    end
    Jekyll::Hooks.register :posts, :post_init do |_|
      puts 'posts   post_init 每次博客被初始化的时候' if DEBUG
    end
    Jekyll::Hooks.register :posts, :pre_render do |_|
      puts 'posts   pre_render 在博客被渲染之前' if DEBUG
    end
    Jekyll::Hooks.register :posts, :post_render do |_|
      puts 'posts   post_render 在博客渲染之后，但是在被写入磁盘之前' if DEBUG
    end
    Jekyll::Hooks.register :posts, :post_write do |_|
      puts 'posts   post_write 在博客被写入磁盘之后' if DEBUG
    end
    Jekyll::Hooks.register :documents, :post_init do |_|
      puts 'documents   post_init 每次文档被初始化的时候' if DEBUG
    end
    Jekyll::Hooks.register :documents, :pre_render do |_|
      puts 'documents   pre_render 在渲染文档之前' if DEBUG
    end
    Jekyll::Hooks.register :documents, :post_render do |_|
      puts 'documents   post_render 在渲染文档之后，但是在被写入磁盘之前' if DEBUG
    end
    Jekyll::Hooks.register :documents, :post_write do |_|
      puts 'documents   post_write 在文档被写入磁盘之后' if DEBUG
    end
  end
end