# Copyright 2020 The Codelogia Authors
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
This module implements the gomplate_library rule.
"""

def _gomplate_library_impl(ctx):
    outputs = []

    for template, name in ctx.attr.templates.items():
        output = ctx.actions.declare_file(name)
        template_files = template[DefaultInfo].files.to_list()
        if len(template_files) > 1:
            fail("Target passed as template cannot contain more than 1 file")
        template_file = template_files[0]

        arguments = ctx.actions.args()
        arguments.add("--file", template_file)
        arguments.add("--out", output)

        if ctx.attr.left_delim != "":
            arguments.add("--left-delim", ctx.attr.left_delim)
        if ctx.attr.right_delim != "":
            arguments.add("--right-delim", ctx.attr.right_delim)

        for datasource, datasource_name in ctx.attr.datasources.items():
            datasource_files = datasource[DefaultInfo].files.to_list()
            if len(datasource_files) > 1:
                fail("Target passed as datasource cannot contain more than 1 file")
            datasource_file = datasource_files[0]
            arguments.add(
                "--datasource",
                "{name}={datasource}".format(
                    name = datasource_name,
                    datasource = datasource_file.path,
                ),
            )

        ctx.actions.run(
            executable = ctx.executable._gomplate,
            arguments = [arguments],
            inputs = [template_file] + ctx.files.datasources,
            outputs = [output],
        )

        outputs.append(output)

    return [DefaultInfo(files = depset(outputs))]

gomplate_library = rule(
    implementation = _gomplate_library_impl,
    attrs = {
        "datasources": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "A set of 'file: name' datasources to be passed to gomplate",
        ),
        "left_delim": attr.string(
            default = "",
            doc = "The left delimiter to be used with gomplate",
        ),
        "right_delim": attr.string(
            default = "",
            doc = "The right delimiter to be used with gomplate",
        ),
        "templates": attr.label_keyed_string_dict(
            allow_files = True,
            doc = """A set of templates to be rendered using gomplate,
            where the keys are the templates and the values are the output names""",
            mandatory = True,
        ),
        "_gomplate": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@gomplate//:gomplate",
            executable = True,
        ),
    },
)
