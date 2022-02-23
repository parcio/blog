# ParCIO Blog

The ParCIO blog is generated using [Hugo](https://gohugo.io/).

## Create New Post

Use the following command to create a new post.
`YYYY` should be replaced by the current year and `MM` should be replaced by the current month.

```console
$ hugo new posts/YYYY/MM/short-title/index.md
```

The post template already includes some common boilerplate.
For everything else, please take a look at the existing posts;
their souce can be found in `content/posts`.

Resources such as code, images etc. should be put in the post's directory.

## Create New Author

If you have not published a post yet, you will have to create your author metadata.
Author handles usually follow the format `firstname.lastname`.
To set everything up, please create a new file called `data/authors/firstname.lastname.yml` with the following content:

```yaml
name: Firstname Lastname
```

## Preview Locally

Hugo supports starting a local webserver for preview purposes using the following command.

```console
$ hugo server
```
