using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibroSphere.Application.Abstractions.Data
{
    // Database connection for using Dapper for Queries
    public interface ISqlConnectionFactory
    {
        IDbConnection CreateConnection();
    }
}
