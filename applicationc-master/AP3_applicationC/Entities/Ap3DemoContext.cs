using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Pomelo.EntityFrameworkCore.MySql.Scaffolding.Internal;

namespace AP3_applicationC.Entities;

public partial class Ap3DemoContext : DbContext
{
    public Ap3DemoContext()
    {
    }

    public Ap3DemoContext(DbContextOptions<Ap3DemoContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Cache> Caches { get; set; }

    public virtual DbSet<CacheLock> CacheLocks { get; set; }

    public virtual DbSet<FailedJob> FailedJobs { get; set; }

    public virtual DbSet<Job> Jobs { get; set; }

    public virtual DbSet<JobBatch> JobBatches { get; set; }

    public virtual DbSet<Migration> Migrations { get; set; }

    public virtual DbSet<Parametrage> Parametrages { get; set; }

    public virtual DbSet<PersonalAccessToken> PersonalAccessTokens { get; set; }

    public virtual DbSet<Prestation> Prestations { get; set; }

    public virtual DbSet<Reservation> Reservations { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<Session> Sessions { get; set; }

    public virtual DbSet<Utilisateur> Utilisateurs { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseMySql("server=192.168.10.16;port=3306;user=ap3_soundbox-3;password=FFvkzgyb;database=ap3_soundbox", Microsoft.EntityFrameworkCore.ServerVersion.Parse("8.4.1-mysql"));

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .UseCollation("utf8mb4_0900_ai_ci")
            .HasCharSet("utf8mb4");

        modelBuilder.Entity<Cache>(entity =>
        {
            entity.HasKey(e => e.Key).HasName("PRIMARY");

            entity
                .ToTable("cache")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.Expiration, "cache_expiration_index");

            entity.Property(e => e.Key).HasColumnName("key");
            entity.Property(e => e.Expiration).HasColumnName("expiration");
            entity.Property(e => e.Value)
                .HasColumnType("mediumtext")
                .HasColumnName("value");
        });

        modelBuilder.Entity<CacheLock>(entity =>
        {
            entity.HasKey(e => e.Key).HasName("PRIMARY");

            entity
                .ToTable("cache_locks")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.Expiration, "cache_locks_expiration_index");

            entity.Property(e => e.Key).HasColumnName("key");
            entity.Property(e => e.Expiration).HasColumnName("expiration");
            entity.Property(e => e.Owner)
                .HasMaxLength(255)
                .HasColumnName("owner");
        });

        modelBuilder.Entity<FailedJob>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity
                .ToTable("failed_jobs")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => new { e.Connection, e.Queue, e.FailedAt }, "failed_jobs_connection_queue_failed_at_index");

            entity.HasIndex(e => e.Uuid, "failed_jobs_uuid_unique").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Connection).HasColumnName("connection");
            entity.Property(e => e.Exception).HasColumnName("exception");
            entity.Property(e => e.FailedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp")
                .HasColumnName("failed_at");
            entity.Property(e => e.Payload).HasColumnName("payload");
            entity.Property(e => e.Queue).HasColumnName("queue");
            entity.Property(e => e.Uuid).HasColumnName("uuid");
        });

        modelBuilder.Entity<Job>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity
                .ToTable("jobs")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.Queue, "jobs_queue_index");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Attempts).HasColumnName("attempts");
            entity.Property(e => e.AvailableAt).HasColumnName("available_at");
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
            entity.Property(e => e.Payload).HasColumnName("payload");
            entity.Property(e => e.Queue).HasColumnName("queue");
            entity.Property(e => e.ReservedAt).HasColumnName("reserved_at");
        });

        modelBuilder.Entity<JobBatch>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity
                .ToTable("job_batches")
                .UseCollation("utf8mb4_unicode_ci");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CancelledAt).HasColumnName("cancelled_at");
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
            entity.Property(e => e.FailedJobIds).HasColumnName("failed_job_ids");
            entity.Property(e => e.FailedJobs).HasColumnName("failed_jobs");
            entity.Property(e => e.FinishedAt).HasColumnName("finished_at");
            entity.Property(e => e.Name)
                .HasMaxLength(255)
                .HasColumnName("name");
            entity.Property(e => e.Options)
                .HasColumnType("mediumtext")
                .HasColumnName("options");
            entity.Property(e => e.PendingJobs).HasColumnName("pending_jobs");
            entity.Property(e => e.TotalJobs).HasColumnName("total_jobs");
        });

        modelBuilder.Entity<Migration>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity
                .ToTable("migrations")
                .UseCollation("utf8mb4_unicode_ci");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Batch).HasColumnName("batch");
            entity.Property(e => e.Migration1)
                .HasMaxLength(255)
                .HasColumnName("migration");
        });

        modelBuilder.Entity<Parametrage>(entity =>
        {
            entity.HasKey(e => e.Idparam).HasName("PRIMARY");

            entity
                .ToTable("parametrage")
                .UseCollation("utf8mb4_unicode_ci");

            entity.Property(e => e.Idparam).HasColumnName("idparam");
            entity.Property(e => e.Libelleparam)
                .HasMaxLength(128)
                .HasColumnName("libelleparam");
            entity.Property(e => e.Uniteparam)
                .HasMaxLength(50)
                .HasColumnName("uniteparam");
            entity.Property(e => e.Valeurparam)
                .HasMaxLength(128)
                .HasColumnName("valeurparam");
        });

        modelBuilder.Entity<PersonalAccessToken>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity
                .ToTable("personal_access_tokens")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.ExpiresAt, "personal_access_tokens_expires_at_index");

            entity.HasIndex(e => e.Token, "personal_access_tokens_token_unique").IsUnique();

            entity.HasIndex(e => new { e.TokenableType, e.TokenableId }, "personal_access_tokens_tokenable_type_tokenable_id_index");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Abilities)
                .HasColumnType("text")
                .HasColumnName("abilities");
            entity.Property(e => e.CreatedAt)
                .HasColumnType("timestamp")
                .HasColumnName("created_at");
            entity.Property(e => e.ExpiresAt)
                .HasColumnType("timestamp")
                .HasColumnName("expires_at");
            entity.Property(e => e.LastUsedAt)
                .HasColumnType("timestamp")
                .HasColumnName("last_used_at");
            entity.Property(e => e.Name)
                .HasColumnType("text")
                .HasColumnName("name");
            entity.Property(e => e.Token)
                .HasMaxLength(64)
                .HasColumnName("token");
            entity.Property(e => e.TokenableId).HasColumnName("tokenable_id");
            entity.Property(e => e.TokenableType).HasColumnName("tokenable_type");
            entity.Property(e => e.UpdatedAt)
                .HasColumnType("timestamp")
                .HasColumnName("updated_at");
        });

        modelBuilder.Entity<Prestation>(entity =>
        {
            entity.HasKey(e => e.Idprestation).HasName("PRIMARY");

            entity
                .ToTable("prestation")
                .UseCollation("utf8mb4_unicode_ci");

            entity.Property(e => e.Idprestation).HasColumnName("idprestation");
            entity.Property(e => e.Libelleprestation)
                .HasMaxLength(128)
                .HasColumnName("libelleprestation");
            entity.Property(e => e.Montantprestation)
                .HasPrecision(5, 2)
                .HasColumnName("montantprestation");
        });

        modelBuilder.Entity<Reservation>(entity =>
        {
            entity.HasKey(e => e.Idreservation).HasName("PRIMARY");

            entity
                .ToTable("reservation")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.Idprestation, "reservation_idprestation_foreign");

            entity.HasIndex(e => e.Idutilisateur, "reservation_idutilisateur_foreign");

            entity.Property(e => e.Idreservation).HasColumnName("idreservation");
            entity.Property(e => e.Datedebut).HasColumnName("datedebut");
            entity.Property(e => e.Heuredebut)
                .HasColumnType("time")
                .HasColumnName("heuredebut");
            entity.Property(e => e.Idprestation)
                .HasDefaultValueSql("'99'")
                .HasColumnName("idprestation");
            entity.Property(e => e.Idutilisateur).HasColumnName("idutilisateur");
            entity.Property(e => e.Validationpresence).HasColumnName("validationpresence");

            entity.HasOne(d => d.IdprestationNavigation).WithMany(p => p.Reservations)
                .HasForeignKey(d => d.Idprestation)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reservation_idprestation_foreign");

            entity.HasOne(d => d.IdutilisateurNavigation).WithMany(p => p.Reservations)
                .HasForeignKey(d => d.Idutilisateur)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("reservation_idutilisateur_foreign");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.Idrole).HasName("PRIMARY");

            entity
                .ToTable("role")
                .UseCollation("utf8mb4_unicode_ci");

            entity.Property(e => e.Idrole).HasColumnName("idrole");
            entity.Property(e => e.Libellerole)
                .HasMaxLength(128)
                .HasColumnName("libellerole");
        });

        modelBuilder.Entity<Session>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity
                .ToTable("sessions")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.LastActivity, "sessions_last_activity_index");

            entity.HasIndex(e => e.UserId, "sessions_user_id_index");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.IpAddress)
                .HasMaxLength(45)
                .HasColumnName("ip_address");
            entity.Property(e => e.LastActivity).HasColumnName("last_activity");
            entity.Property(e => e.Payload).HasColumnName("payload");
            entity.Property(e => e.UserAgent)
                .HasColumnType("text")
                .HasColumnName("user_agent");
            entity.Property(e => e.UserId).HasColumnName("user_id");
        });

        modelBuilder.Entity<Utilisateur>(entity =>
        {
            entity.HasKey(e => e.Idutilisateur).HasName("PRIMARY");

            entity
                .ToTable("utilisateur")
                .UseCollation("utf8mb4_unicode_ci");

            entity.HasIndex(e => e.Idrole, "utilisateur_idrole_foreign");

            entity.Property(e => e.Idutilisateur).HasColumnName("idutilisateur");
            entity.Property(e => e.CreatedAt)
                .HasColumnType("timestamp")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(128)
                .HasColumnName("email");
            entity.Property(e => e.Idrole).HasColumnName("idrole");
            entity.Property(e => e.Motpasse)
                .HasMaxLength(128)
                .HasColumnName("motpasse");
            entity.Property(e => e.Nom)
                .HasMaxLength(128)
                .HasColumnName("nom");
            entity.Property(e => e.Prenom)
                .HasMaxLength(128)
                .HasColumnName("prenom");
            entity.Property(e => e.ResetToken)
                .HasMaxLength(64)
                .HasColumnName("reset_token");
            entity.Property(e => e.ResetTokenExpiresAt)
                .HasColumnType("datetime")
                .HasColumnName("reset_token_expires_at");
            entity.Property(e => e.TwoFactorCode)
                .HasMaxLength(10)
                .HasColumnName("two_factor_code");
            entity.Property(e => e.TwoFactorExpiresAt)
                .HasColumnType("datetime")
                .HasColumnName("two_factor_expires_at");
            entity.Property(e => e.UpdatedAt)
                .HasColumnType("timestamp")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.IdroleNavigation).WithMany(p => p.Utilisateurs)
                .HasForeignKey(d => d.Idrole)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("utilisateur_idrole_foreign");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
