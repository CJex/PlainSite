PlainSite
=========

PlainSite：A Truely Hackable Static Site Generator.

<strong style="font-size:larger; color:red;"> This project is no longer maintained! </strong>

## Getting Started

1. Install [Ruby](https://www.ruby-lang.org/) and then:
```bash
gem install PlainSite
```

2. Init site:
```bash
cd mysite
plainsite init
```

3. Create new post:
```bash
plainsite newpost post-slug 'Hello,wolrd!This is the title!'
```

4. Preview site,open <http://localhost:1990/> in your web browser.
```bash
plainsite serve
```

5. Configure '_src/config.yml'
```yaml
url: http://example.com   # You site's domain or url prefix.
disqus_id:                # Config to enable disqus comments.
name: YouBlogName
author: YouName
```

6. Build site static pages:
```bash
plainsite build
```

## Features
1. Give you back full control of generating pages.
2. Along with Git,PlainSite can generate only updated posts' corresponding pages.
3. Builtin live reload preview web server.
4. Generate relative url thus enable to view site through `file://` protocal without any web server.
5. Auto clean deleted posts' corresponding pages.
6. Pagination becomes incredibly easy.


## Site Directory Structrue

Run `plainsite init` will get things done.

```
.
├── .git
├── .nojekyll
└── _src
  ├── assets
  ├── data
  │   ├── category
  │   ├── demo-post.html
  │   └── 2012-12-25-hello-world.md
  ├── templates
  │   └── post.html
  ├── routes.rb
  └── config.yml
```

All files under `_src` directory are the source files.Here is each sub directory's usage:

1. `assets`: Put all your static files in it for easier maintenance. PlainSite will copy them to site's root on building.For example, if you want to [add a CNAME file to enable custom domain](https://help.github.com/articles/adding-a-cname-file-to-your-repository/),you need to put it at `/_src/assets/CNAME`,so PlainSite will copy it to `/CNAME`.
2. `data`: Put your post files here,each file corresponds to a `Post`,each directory corresponds to a `Category`.
3. `templates`: ERB template files.
4. `routes.rb`: All custom tricks: url pattern,pagination, etc...
5. `config.yml`: Site configuration.


## Command Usages
1. Run `plainsite build --local` will use relative url in output pages.
2. Run `plainsite build --all` will force generate all pages.
1. Run `plainsite help` for more command line options.

## Code Highlight
Example post file content:
```html
---
title: Hello,world!
---

**Here is post's content!**

Ruby：
<highlight ruby>
puts "Hello,world!"
</highlight>

Python，with line numbers：
<highlight python linenos>
def hello():
  print("Hello")
</highlight>

Specify the start line number:
<highlight php linenos=20>
echo "PlainSite";
ob_flush();
</highlight>

If there is no line feed char in code, it will output an inline code element:<highlight>puts "Inline"</highlight>
```

## Customation


### Concepts:

1. Post：`PlainSite::Data::Post`

   Plain text file under `_src/data/`,represents one post.

2. Category：`PlainSite::Data::Category`

   Directory under  `_src/data/`.

3. Template

   ERB template files Under `_src/templates/` directory.

4. Routes

   Ruby script at ```_src/routes.rb```.


**PlainSite will ignore Post、Template files or Category directories which prefix with underscore.**


### Post and Category

Files under site's `_src/data/` directory represent Post：
```
_src/data/2011-02-28-hello-world.md
```
The `2011-02-28` is post's created date(optional);`hello-world` is post's slug(required).It's not allowed that two post files under the same category directory have the same slug;The `.md` ,viz. extname,represents Post's content type(PlainSite only support Markdown and HTML two content types,corresponding extnames are `md` and `html`.

Post file content must starts with [YAML-Front format header](http://jekyllrb.com/docs/frontmatter/),and at least contains a `title` property.

The Post file's path relative to `_src/data` represents its Category.You can use directory as category to organize posts.For example,here are two categories:`programming` and `essays`:
```
_src/data/programming/2011-02-28-hello-world.md
_src/data/essays/2013-04-22-life-is-a-game.md
```

Category.data_id is the path relative to `_src/data`.

Post.data_id equals `Post.category.data_id + "/" + Post.slug` .

You can put an `_meta.yml` file under Category's directory to custom its attributes,such as `display_name`:
Here is an example file at `_src/data/programming/_meta.yml`：
```yaml
display_name: ProgrammingLife
```

All properties specified in post's YAML header can be accessed via Post object directly.


## Routes and Templates
File `_src/routes.rb` is used to custom url pattern and all what you want.
The `_src/routes.rb` file is just a Ruby script that loaded and executed by PlainSite.
You can use global variable `$site` to access current `PlainSite::Site` instance object.
Through `$site.data` to get site root category(`_src/data`),`PlainSite::Data::Category` instance object.
For examples：

```ruby
# coding:utf-8

$site.route(
  # url_pattern specify the output page's urlpath（relative to site root）
  url_pattern: 'index.html',

  # template file path relative to `_src/templates/`
  template: 'index.html',

  # The 'data' will be sent to template to render.
  # If data is Array/PostList object, It will render each item with template into seperated pages.
  # ERB template's context is which 'data' property specified，
  # ERB code can access its key or method directly,
  # e.g. here 'index.html' template's erb code can directly use site and demo variables
  data: {site: $site, demo:123},
  build_anyway: true # Force build this route every time.
)

$site.route( # Generate single post page
  url_pattern: 'about.html',
  data: $site.data / :about , # Retrieve the Post which data_id is 'about'
  template: 'post.html'
)

$site.route( # Generate posts under essays category
  # ur_pattern: '{date.year}/{date.month}/{date.day}/{slug}.html',
  url_pattern: '{data_id}.html', # url_pattern support variable replacement
                                 # which is Post's property
  data: 'essays/*', # Get all posts under 'essays',return PlainSite::Data::PostList instance
  template: 'post.html'
)

$site.route(
  url_pattern: 'programming/{slug}.html',
  data: $site.data / :programming / :*, # synonym of 'programming/*'
  template: 'post.html'
)

# $site.data.subs are categories under '_src/data',return Category[]
$site.data.subs.each do |category|
  $site.route(
    url_pattern: "#{category.name}/{slug}.html",
    # category.posts/5 means category.paginate(page_size:5),return PostListPage[]
    data: category.posts/5 , # category.posts is same as 'category / :* '
    template: 'list.html'
  )
end

```


Template system supports layout,specified in its YAML Header：
```erb
---
layout: base.html   # file path relative to self
---
<% content_for :page_title do %>
  <%=title%> - <%=site.name %>
<% end %>
<% content_for :page_content do %>
  <h1><%=title%></h1>
  <p>Date：<%=date%></p>
  <%=content%>
  <hr />

  Use site.url_for to get url which affected by 'plainsite build --local' and resulted in relative url.
  <%=site.url_for 'essays/hello' %>

  Also support includes.
  <%=include 'footer.html' %>
<% end %>
```

The `base.html` contents：

```erb
<html>
<head>
  <title><%=yield :page_title%></title>
</head>
<body>
  <%=yield :page_content%>
</body>
</html>
```

## More

1. Run `gem server` to read PlainSite rdoc.
2. Read the source code.

## Sites using PlainSite

<span style="font-size:larger">Jex's Blog: <a href="https://jex.im/">https://jex.im/</a></span>





