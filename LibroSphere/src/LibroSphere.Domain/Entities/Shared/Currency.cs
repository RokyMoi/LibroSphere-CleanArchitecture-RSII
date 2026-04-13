using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;

namespace LibroSphere.Domain.Entities.Shared
{
    public record Currency
    {
        internal static readonly Currency None = new(" ");
        public static readonly Currency Bam = new("BAM");
        public static readonly Currency Usd = new("USD");
        public static readonly Currency Eur = new("EUR");

        [JsonConstructor]
        public Currency(string code) => Code = code;

        public static Currency FromCode(string code)
        {
            return Currencys.FirstOrDefault(x => x.Code == code)
                ?? throw new ApplicationException("There is no currency with that code");
        }

        public string Code { get; init; }

        public static readonly IReadOnlyCollection<Currency> Currencys = new[]
        {
            Bam,
            Usd,
            Eur
        };
    }
}
