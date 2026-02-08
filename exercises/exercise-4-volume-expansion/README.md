# Exercise 4: Volume Expansion

This exercise demonstrates expanding a volume without data loss.

## Steps:

1. **Create StorageClass** with `allowVolumeExpansion: true`
2. **Create PVC** with initial 1Gi size
3. **Deploy Pod** and write test data
4. **Expand PVC** to 2Gi
5. **Verify** the pod sees expanded storage and data is intact