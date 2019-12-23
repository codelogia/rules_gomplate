# Copyright 2019 The Codelogia Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
This module exports the repositories required by the gomplate rules.
"""

def gomplate_repositories(**kwargs):
    _gomplate_binary(
        name = "gomplate",
        **kwargs
    )

def _gomplate_binary_impl(ctx):
    info = None
    if ctx.os.name == "mac os x":
        info = ctx.attr.darwin
    elif ctx.os.name == "linux":
        info = ctx.attr.linux
    elif ctx.os.name == "windows":
        info = ctx.attr.windows
    else:
        fail("Unsupported operating system: {}".format(ctx.os.name))

    ctx.download(
        output = ctx.attr.name,
        executable = True,
        **info
    )

    build_contents = 'package(default_visibility = ["//visibility:public"])\n'
    build_contents += 'exports_files(["{name}"])\n'.format(name = ctx.attr.name)
    ctx.file("BUILD.bazel", build_contents)

_gomplate_binary = repository_rule(
    implementation = _gomplate_binary_impl,
    attrs = {
        "darwin": attr.string_dict(
            default = {
                "sha256": "04a6b6d3a9d67fc56428a4571131f52dd3cc2cedb6ed8e9776db77bff0a72b5b",
                "url": "https://github.com/hairyhenderson/gomplate/releases/download/v3.6.0/gomplate_darwin-amd64-slim",
            },
        ),
        "linux": attr.string_dict(
            default = {
                "sha256": "0867b2d6b23c70143a4ea37705d4308d051317dd0532d7f3063acec21f6cbbc8",
                "url": "https://github.com/hairyhenderson/gomplate/releases/download/v3.6.0/gomplate_linux-amd64-slim",
            },
        ),
        "windows": attr.string_dict(
            default = {
                "sha256": "21c8b8c4a033d212effa660a17da68e3f64af8ab1748b8cc62ef2952182c635e",
                "url": "https://github.com/hairyhenderson/gomplate/releases/download/v3.6.0/gomplate_windows-amd64-slim.exe",
            },
        ),
    },
)
