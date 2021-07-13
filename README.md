# Jekyll Tags Tally

这是一个开箱即用基于 **Tags**（当然你不用 ~~Tags~~这个字段也是可以的）的计数插件。

首先 *Jekyll* 实在是太赞了，各种精美博客层出不穷，而有着免费服务器（国内访问就emm）同时爸爸是 ~微软~的  *GitHub* 更是让我心动不已，成天想着怎么去薅其羊毛。

加上自己对记账这档事情一直没有得心应手的 `app` 供我去瞎嚯嚯。

观察了很久 `jekyll-archive` 这个插件的源码后，鼓捣出来这么一个插件！

记账，分分钟（好了别骂了，我知道你们都是几秒钟！）的事情。

## 那么就开始吧！

* 首先你了解 `jekyll`
* `gem install jekyll-tags-tally`
* 然后编辑 `_config.yml`
* 找到 `plugins:`
```yaml
plugins:
 ...
  - jekyll-tags-tally #启用这个插件
```
* 然后填入以下这一堆乱中有序的配置
```yaml
classify:
  layout:  subjects
  enabled: all
  permalinks:
    year:             "/:year/"
    year_week:        "/:year/:week/"
    month:            "/:year/:month/"
    month_week:       "/:year/:month/:week/"
    day:              "/:year/:month/:day/"
    week:             "/week/:week/"
    subject:          "/subject/:subject/"
    class:            "/class/:class/"
    classes:          "/classes/:classes/"
    subjects:         "/subjects/:subjects/"
    class_subject:    "/class_subject/:class/:subject/"
    class_subjects:   "/class_subjects/:class/:subjects/"
    classes_subjects: "/classes_subjects/:classes/:subjects/"

cjyb: &cjyb
  key:   cjyb
  class: 0
  count: 5
  int: [ 6, 7 ]
  subject: [ 1, 2, 3, 4 ]
  tags: [ '从:3到:4:4:3:4:3:3' ]
  formatter: [ ':sum_2:6:7人:div_2:7:6个' ]

jnts: &jnts
  key:   jnts
  class: 0
  count: 5
  int: [ 6, 7 ]
  subject: [ 1, 2, 3, 4 ]
  tags: [ '从:3到:4' ]
  formatter: [ ':sum_2:6:7人:div_2:7:6个' ]

tally:
  unit: "%s ¥"
  combine: true
  templates:
    - <<: *cjyb
    - <<: *jnts
```

* 这些处理完了之后就可以在你的 `_post` 里面记录你剁手的一生了。
* 新建文件 `1970-01-01.md` 后面不需要名字了！
* 然后在文件内的头部信息里填入

```yaml
date: 1970-01-01
jnts: 
  - 分类，子类，名称，来源，花费，数量，人数，数量
 
```

* 对了！如果不在  `_layouts` 目录里面添加文件的话就什么效果都看不到，下面添加一个查看文件。
```liquid

```
* 最后 `bundle install` 和 `bundle exec jekyll server` 就不用我教了吧？



## 后续看心情支持计划

- [ ] `formatter` 里的简单计算
- [ ] 技术分享
- [ ] 配套的模版
- [ ] 图表绘制
- [ ] 排序
- [ ] 物品生命周期生成