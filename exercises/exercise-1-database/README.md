# Exercise 1: Database Deployment

This exercise demonstrates deploying a PostgreSQL database with persistent storage.

## Steps:

1. **Create PVC for PostgreSQL**: 5Gi with ReadWriteOnce access mode
2. **Deploy PostgreSQL**: Using the official PostgreSQL image with persistent storage
3. **Test Data Persistence**: Create a database, insert data, restart pod
4. **Bonus**: Set up automatic backups with CronJob