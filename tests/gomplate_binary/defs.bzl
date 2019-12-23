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
This module defines a macro for testing the gomplate_binary rule.
"""

def binary_test(
        name,
        expected_output,
        target,
        size = "small"):
    native.sh_test(
        name = name,
        size = size,
        srcs = ["//tests/gomplate_binary:binary_test_runner.sh"],
        args = [
            "'{}'".format(expected_output),
            "$(location {})".format(target),
        ],
        data = [target],
    )
