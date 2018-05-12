/*
 * Copyright 2018, alex at staticlibs.net
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* 
 * File:   hello_chakra.cpp
 * Author: alex
 *
 * Created on May 12, 2018, 1:29 PM
 */

#include <iostream>
#include <string>

#include "v8.h"
#include "libplatform/libplatform.h"

int main() {
    v8::Platform* platform = v8::platform::CreateDefaultPlatform();
    v8::V8::InitializePlatform(platform);
    v8::V8::Initialize();
    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator =
            v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    v8::Isolate* isolate = v8::Isolate::New(create_params);
    auto res = std::string();
    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        v8::Local<v8::Context> context = v8::Context::New(isolate);
        v8::Context::Scope context_scope(context);
        v8::Local<v8::String> source =
                //v8::String::NewFromUtf8(isolate, "'cafe\u0301'.normalize() + ' ' + 'caf\u00E9'.normalize()",
                v8::String::NewFromUtf8(isolate, "42 + 1",
                v8::NewStringType::kNormal).ToLocalChecked();
        v8::Local<v8::Script> script = v8::Script::Compile(context, source).ToLocalChecked();
        v8::Local<v8::Value> result = script->Run(context).ToLocalChecked();
        v8::String::Utf8Value utf8(result);
        res.append(*utf8);
    }
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::ShutdownPlatform();

    if ("43" != res) {
        std::cerr << "Invalid script result: [" << res << "]" << std::endl;
        return 1;
    }

    return 0;
}
