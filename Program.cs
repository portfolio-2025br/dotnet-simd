// ################################################################################
//  Copyright (c) 2025  Claudio André <portfolio-2025br at claudioandre.slmail.me>
//     ____              __                                _       _________  __
//    / __ )____  ____  / /__________ _____ ___  ____     | |     / / ____/ |/ /
//   / __  / __ \/ __ \/ __/ ___/ __ `/ __ `__ \/ __ \    | | /| / / __/  |   /
//  / /_/ / /_/ / /_/ / /_/ /__/ /_/ / / / / / / /_/ /    | |/ |/ / /___ /   |
// /_____/\____/\____/\__/\___/\__,_/_/ /_/ /_/ .___/     |__/|__/_____//_/|_|
//                                           /_/
//
// This program comes with ABSOLUTELY NO WARRANTY; express or implied.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, as expressed in version 2, seen at
// https://www.gnu.org/licenses/gpl-2.0.html
// ################################################################################
// Estudo de caso sobre o uso de SIMD com .NET
// More info at https://github.com/portfolio-2025br/dotnet-simd

using System.Runtime.Intrinsics.X86;

using BenchmarkDotNet.Running;

namespace SIMDPerformance
{
    class Program
    {
        static void Main(string[] args)
        {
            if (!Avx2.IsSupported)
            {
                Console.WriteLine("Infelizmente, AVX2 NOT supported pela sua CPU!");
                return;
            }
            var summary = BenchmarkRunner.Run<SIMDAVX2Performance>();
        }
    }
}