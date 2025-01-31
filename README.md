## Using lintguard
### Add `lintguard` to codeblocks in Markdown files
In any Markdown (.md) file, you can augment a codeblock with lintguard notation.

Consider a hypothetical README.md file with the following codeblock appearing somewhere:

<pre>
```swift lintguard: Package.swift#L1-L19
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LintGuard",
    products: [
        .executable(
            name: "lintguard",
            targets: ["LintGuard"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LintGuard"
        ),
    ]
)
```
</pre>

The main bit of interest is the first line
<code>```swift lintguard: Package.swift#L1-L19</code>
- the first three backticks <code>```</code> are the start of a standard markdown code block
- `swift` bit is also standard in markdown is the language identifier
- after the language identifier we see the token `lintguard:` this indicates to lintguard that this code block should be checked
- after the `lintguard` token, we see `Package.swift` this indicates that the codeblock is referencing the `Package.swift` file
- after the filename, we see `#L1-L19`, this means that the codeblock matches lines 1-19 of the `Package.swift` file

### Using lintguard to detect out of date codeblocks
Consider the hypothetical README.md from the previous section, once the tool is installed, simply invoke it with the paths to one or more Markdown (.md) files:
```
$ lintguard README.md
```

If any `lintguard` code blocks exist in README.md, lintguard will process them to ensure any guarded code blocks are up-to-date

We can even use it on the `README.md` file you are currently reading:

This is line 49, Hello World!

This code block will pass:
````
```markdown lintguard: README.md#L49
This is line 49, Hello World!
```
````

And this one will fail:
````
```markdown lintguard: README.md#L49
This is line 49, Hello?
```
````

Try it!
```
$ swift run lintguard README.md
```

## Installing lintguard

Simply invoke make
```
$ make
```

and `lintguard` will be in the `bin/release` folder, from here you can move it to `PATH`, copy it to `/usr/local` etc...
