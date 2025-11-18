# Memory Optimization Guide

This guide explains how the MySQL configuration is optimized for different memory sizes, particularly for low-memory instances like Render's Starter plan (512MB RAM).

## Current Configuration (512MB RAM)

The default `config/user.cnf` is optimized for **512MB total RAM**. Here's the memory breakdown:

### Memory Allocation

```
Total RAM:           512MB
├─ OS Overhead:      ~100-150MB
├─ MySQL Base:       ~50-100MB
└─ InnoDB Buffer:    128MB (25% of total)
```

### Key Settings for 512MB

| Setting | Value | Reason |
|---------|-------|--------|
| `innodb_buffer_pool_size` | 128M | Main memory pool for InnoDB (25% of RAM) |
| `innodb_buffer_pool_instances` | 1 | Single instance reduces overhead |
| `innodb_log_file_size` | 32M | Reduced from 256M to save memory |
| `innodb_log_buffer_size` | 8M | Reduced from 64M |
| `max_connections` | 50 | Each connection uses 2-4MB |
| `table_open_cache` | 200 | Reduced from 4000 |
| `table_definition_cache` | 400 | Reduced from 2000 |
| `tmp_table_size` | 16M | Reduced from 64M |
| `max_heap_table_size` | 16M | Reduced from 64M |
| Binary Logging | Disabled | Saves memory and I/O |

## Scaling Up

### 1GB RAM Configuration

```ini
innodb_buffer_pool_size=512M
innodb_buffer_pool_instances=2
innodb_log_file_size=64M
innodb_log_buffer_size=16M
max_connections=100
table_open_cache=1000
table_definition_cache=1000
tmp_table_size=32M
max_heap_table_size=32M
# Enable binary logging if needed
log_bin=mysql-bin
max_binlog_size=64M
```

### 2GB RAM Configuration

```ini
innodb_buffer_pool_size=1G
innodb_buffer_pool_instances=4
innodb_log_file_size=128M
innodb_log_buffer_size=32M
max_connections=200
table_open_cache=2000
table_definition_cache=1500
tmp_table_size=64M
max_heap_table_size=64M
log_bin=mysql-bin
max_binlog_size=100M
```

### 4GB+ RAM Configuration

```ini
innodb_buffer_pool_size=2G
innodb_buffer_pool_instances=4
innodb_log_file_size=256M
innodb_log_buffer_size=64M
max_connections=200
table_open_cache=4000
table_definition_cache=2000
tmp_table_size=64M
max_heap_table_size=64M
log_bin=mysql-bin
max_binlog_size=100M
```

## Memory Usage Calculation

### Per Connection Memory

Each MySQL connection uses approximately:
- **Base overhead**: ~2-4MB per connection
- **Thread buffers**: ~256KB per connection
- **Sort buffers**: ~256KB per connection (if sorting)

**Formula:**
```
Total Connection Memory = max_connections × 3MB
```

For 50 connections: `50 × 3MB = 150MB`

### InnoDB Buffer Pool

The buffer pool is the most important memory setting:
- **Too small**: Frequent disk I/O, slow performance
- **Too large**: OOM (Out of Memory) errors, system instability

**Recommended:**
- 512MB RAM: 128M (25%)
- 1GB RAM: 512M (50%)
- 2GB+ RAM: 70-80% of available RAM

### Other Memory Components

```
MySQL Memory Usage = 
  + InnoDB Buffer Pool
  + Connection Memory (max_connections × 3MB)
  + Table Cache (table_open_cache × ~50KB)
  + Temporary Tables (tmp_table_size × active queries)
  + Log Buffers (innodb_log_buffer_size)
  + Binary Logs (if enabled)
  + OS Overhead (~100-150MB)
```

## Troubleshooting Out of Memory

### Symptoms

- Container crashes or restarts
- "Out of memory" errors in logs
- MySQL fails to start
- System becomes unresponsive

### Solutions

1. **Reduce `innodb_buffer_pool_size`**
   ```ini
   # Try reducing by 25%
   innodb_buffer_pool_size=96M  # from 128M
   ```

2. **Reduce `max_connections`**
   ```ini
   # Reduce connections
   max_connections=30  # from 50
   ```

3. **Disable Binary Logging** (if not needed)
   ```ini
   # Comment out or remove
   # log_bin=mysql-bin
   ```

4. **Reduce Table Caches**
   ```ini
   table_open_cache=100
   table_definition_cache=200
   ```

5. **Reduce Temporary Table Sizes**
   ```ini
   tmp_table_size=8M
   max_heap_table_size=8M
   ```

6. **Upgrade Instance Size**
   - Consider upgrading to 1GB RAM if possible
   - Better performance and stability

## Monitoring Memory Usage

### Check Current Memory Usage

```sql
-- Check InnoDB buffer pool usage
SHOW STATUS LIKE 'Innodb_buffer_pool%';

-- Check connection count
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';

-- Check table cache usage
SHOW STATUS LIKE 'Open_tables';
SHOW VARIABLES LIKE 'table_open_cache';
```

### Monitor from Container

```bash
# Check container memory usage
docker stats <container-name>

# Check MySQL process memory
docker exec <container> ps aux | grep mysqld
```

### Render Dashboard

- Go to your service dashboard
- Check "Metrics" tab for memory usage
- Set up alerts for high memory usage

## Best Practices

1. **Start Conservative**: Begin with lower settings and increase if needed
2. **Monitor First**: Watch memory usage before optimizing
3. **Test Changes**: Always test configuration changes in staging
4. **Leave Headroom**: Never allocate 100% of RAM to MySQL
5. **Consider Workload**: Adjust based on your actual usage patterns

## Quick Reference

| RAM | Buffer Pool | Connections | Binary Log |
|-----|-------------|-------------|------------|
| 512MB | 128M | 50 | Disabled |
| 1GB | 512M | 100 | Optional |
| 2GB | 1G | 200 | Enabled |
| 4GB+ | 2G+ | 200+ | Enabled |

## Additional Resources

- [MySQL Memory Usage](https://dev.mysql.com/doc/refman/8.0/en/memory-use.html)
- [InnoDB Buffer Pool](https://dev.mysql.com/doc/refman/8.0/en/innodb-buffer-pool.html)
- [Optimizing for Small Systems](https://dev.mysql.com/doc/refman/8.0/en/optimizing-for-small-systems.html)

