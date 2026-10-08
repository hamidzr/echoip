package http

import (
	"fmt"
	"net"
	"sync"
	"testing"
)

func TestCacheCapacity(t *testing.T) {
	var tests = []struct {
		addCount, capacity, size int
		evictions                uint64
	}{
		{1, 0, 0, 0},
		{1, 2, 1, 0},
		{2, 2, 2, 0},
		{3, 2, 2, 1},
		{10, 5, 5, 5},
	}
	for i, tt := range tests {
		c := NewCache(tt.capacity)
		var responses []Response
		for i := 0; i < tt.addCount; i++ {
			ip := net.ParseIP(fmt.Sprintf("192.0.2.%d", i))
			r := Response{IP: ip}
			responses = append(responses, r)
			c.Set(ip, r)
		}
		if got := len(c.entries); got != tt.size {
			t.Errorf("#%d: len(entries) = %d, want %d", i, got, tt.size)
		}
		if got := c.evictions; got != tt.evictions {
			t.Errorf("#%d: evictions = %d, want %d", i, got, tt.evictions)
		}
		if tt.capacity > 0 && tt.addCount > tt.capacity && tt.capacity == tt.size {
			lastAdded := responses[tt.addCount-1]
			if _, ok := c.Get(lastAdded.IP); !ok {
				t.Errorf("#%d: Get(%s) = (_, %t), want (_, %t)", i, lastAdded.IP.String(), ok, !ok)
			}
			firstAdded := responses[0]
			if _, ok := c.Get(firstAdded.IP); ok {
				t.Errorf("#%d: Get(%s) = (_, %t), want (_, %t)", i, firstAdded.IP.String(), ok, !ok)
			}
		}
	}
}

func TestCacheDuplicate(t *testing.T) {
	c := NewCache(10)
	ip := net.ParseIP("192.0.2.1")
	response := Response{IP: ip}
	c.Set(ip, response)
	c.Set(ip, response)
	want := 1
	if got := len(c.entries); got != want {
		t.Errorf("want %d entries, got %d", want, got)
	}
	if got := c.values.Len(); got != want {
		t.Errorf("want %d values, got %d", want, got)
	}
}

func TestCacheReplaceAtCapacity(t *testing.T) {
	for replace := 1; replace <= 3; replace++ {
		t.Run(fmt.Sprint(replace), func(t *testing.T) {
			c := NewCache(3)
			for i := 1; i <= 3; i++ {
				ip := net.ParseIP(fmt.Sprintf("192.0.2.%d", i))
				c.Set(ip, Response{IP: ip, Country: "original"})
			}
			ip := net.ParseIP(fmt.Sprintf("192.0.2.%d", replace))
			c.Set(ip, Response{IP: ip, Country: "updated"})
			if got := c.Stats(); got.Size != 3 || got.Evictions != 0 {
				t.Errorf("replacement changed cache occupancy: %+v", got)
			}
			for i := 1; i <= 3; i++ {
				ip := net.ParseIP(fmt.Sprintf("192.0.2.%d", i))
				response, ok := c.Get(ip)
				if !ok {
					t.Errorf("replacement evicted IP %s", ip)
				} else if i == replace && response.Country != "updated" {
					t.Errorf("replacement kept old response: %+v", response)
				}
			}
		})
	}
}

func TestCacheConcurrentResize(t *testing.T) {
	c := NewCache(3)
	ip := net.ParseIP("192.0.2.1")
	var workers sync.WaitGroup
	workers.Add(2)
	go func() {
		defer workers.Done()
		for i := 0; i < 1000; i++ {
			c.Set(ip, Response{IP: ip})
		}
	}()
	go func() {
		defer workers.Done()
		for i := 0; i < 1000; i++ {
			if err := c.Resize(i % 4); err != nil {
				t.Error(err)
			}
		}
	}()
	workers.Wait()
}

func TestCacheResize(t *testing.T) {
	c := NewCache(10)
	for i := 1; i <= 20; i++ {
		ip := net.ParseIP(fmt.Sprintf("192.0.2.%d", i))
		r := Response{IP: ip}
		c.Set(ip, r)
	}
	if got, want := len(c.entries), 10; got != want {
		t.Errorf("want %d entries, got %d", want, got)
	}
	if got, want := c.evictions, uint64(10); got != want {
		t.Errorf("want %d evictions, got %d", want, got)
	}
	if err := c.Resize(5); err != nil {
		t.Fatal(err)
	}
	if got, want := c.evictions, uint64(0); got != want {
		t.Errorf("want %d evictions, got %d", want, got)
	}
	r := Response{IP: net.ParseIP("192.0.2.42")}
	c.Set(r.IP, r)
	if got, want := len(c.entries), 5; got != want {
		t.Errorf("want %d entries, got %d", want, got)
	}
}
