#ifndef EUPHONIUM_CIRCULAR_BUFFER
#define EUPHONIUM_CIRCULAR_BUFFER

#include <algorithm>
#include <mutex>
#include <cstring>
#include <EuphoniumLog.h>

class CircularBuffer
{
public:
    CircularBuffer(uint8_t static_buffer[], uint32_t buffer_len);

    size_t size() const { return dataSize; }
    size_t capacity() const { return dataCapacity; }
    size_t write(const uint8_t *data, size_t bytes);
    size_t read(uint8_t *data, size_t bytes);
    void emptyBuffer();

private:
    std::mutex bufferMutex;
    size_t begIndex = 0;
    size_t endIndex = 0;
    size_t dataSize = 0;
    size_t dataCapacity = 0;
    uint8_t *buffer;
};

#endif
