using LibroSphere.Application.Exceptions;
using LibroSphere.Domain.Abstraction;
using MediatR;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Dapper.SqlMapper;

namespace LIbroSphere.Infrastructure
{
    public sealed class ApplicationDbContext : DbContext, IUnitOfWork
    {
        private readonly IPublisher _publisher;


        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options, IPublisher publisher)
    : base(options)
        {
            _publisher = publisher;
        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
            base.OnModelCreating(modelBuilder);
        }
        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var result = await base.SaveChangesAsync(cancellationToken);

                await PublishDomainEventAsync();

                return result;
            }
            catch (DbUpdateConcurrencyException ex) {
          //Race condition fix. - If many users change same data.
                throw new ConcurrencyException("Concurrency exception occured", ex);

            }
        }
    //Sumarry: When publisher(mediaTr) publish domain events. - We later handle that event after method: SaveChangesAsync
    private async Task PublishDomainEventAsync()
        {
            var domainEvents = ChangeTracker //Point is.. We are watching every entity, if there there is change
                .Entries<BaseEntity>()           //then there is event, so we can publish to handle
                .Select(entry => entry.Entity)
                .SelectMany(entity =>
                {
                    var domainEvents = entity.GetDomainEvents();      //Methods that we added in our BaseEntity.

                    entity.ClearDomainEvents();

                    return domainEvents;
                })
                .ToList();

            foreach (var domainEvent in domainEvents)
            {
                await _publisher.Publish(domainEvent);
            }
        }
    }
}
