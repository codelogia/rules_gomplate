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
This module implements the gomplate_binary rule.
"""

def _gomplate_binary_impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.name)

    arguments = ctx.actions.args()
    arguments.add("--file", ctx.file.template)
    arguments.add("--out", output)

    for datasource, name in ctx.attr.datasources.items():
        files = datasource[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("Target passed as datasource cannot contain more than 1 file")
        file = files[0]
        arguments.add(
            "--datasource",
            "{name}={datasource}".format(
                name = name,
                datasource = file.path,
            ),
        )

    runtime_files = []
    _files_dict = {}
    for runtime_file in ctx.attr.runtime_files:
        for file in runtime_file[DefaultInfo].files.to_list():
            runtime_files.append(file)
            basename = file.short_path.rpartition("/")[-1]
            _files_dict[basename] = file.short_path

    _files = ctx.actions.declare_file("_files_{target_name}.json".format(target_name = ctx.attr.name))
    ctx.actions.write(_files, struct(**_files_dict).to_json())
    arguments.add(
        "--datasource",
        "_files={files}".format(files = _files.path),
    )

    runtime_tools = []
    runtime_tools_runfiles = []
    _tools_dict = {}
    for tool in ctx.attr.runtime_tools:
        default_info = tool[DefaultInfo]
        runtime_tools_runfiles.append(default_info.default_runfiles)
        executable = default_info.files_to_run.executable
        executable_basename = executable.short_path.rpartition("/")[-1]
        _tools_dict[executable_basename] = executable.short_path

    _tools = ctx.actions.declare_file("_tools_{target_name}.json".format(target_name = ctx.attr.name))
    ctx.actions.write(_tools, struct(**_tools_dict).to_json())
    arguments.add(
        "--datasource",
        "_tools={tools}".format(tools = _tools.path),
    )

    ctx.actions.run(
        executable = ctx.executable._gomplate,
        arguments = [arguments],
        inputs = [
            ctx.file.template,
            _files,
            _tools,
        ] + ctx.files.datasources,
        outputs = [output],
    )

    runfiles = ctx.runfiles(files = runtime_files)
    for rf in runtime_tools_runfiles:
        runfiles = runfiles.merge(rf)

    return [DefaultInfo(
        executable = output,
        runfiles = runfiles,
    )]

gomplate_binary = rule(
    implementation = _gomplate_binary_impl,
    attrs = {
        "datasources": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "A set of 'file: name' datasources to be passed to gomplate",
        ),
        "runtime_files": attr.label_list(
            allow_files = True,
            doc = "A list of files to be used at runtime",
        ),
        "runtime_tools": attr.label_list(
            doc = "A list of executable tools to be used at runtime",
        ),
        "template": attr.label(
            allow_single_file = True,
            doc = "The template to be rendered using gomplate",
            mandatory = True,
        ),
        "_gomplate": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@gomplate//:gomplate",
            executable = True,
        ),
    },
    executable = True,
)
