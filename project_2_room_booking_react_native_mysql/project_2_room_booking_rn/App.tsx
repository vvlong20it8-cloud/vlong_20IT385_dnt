import React, { useEffect, useMemo, useState } from 'react';
import {
  Alert, FlatList, Modal, Platform, Pressable, SafeAreaView, ScrollView,
  StatusBar, StyleSheet, Text, TextInput, View
} from 'react-native';
import { StatusBar as ExpoStatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';

type Room = {
  id: string;
  name: string;
  building: string;
  floor: string;
  capacity: number;
  type: 'Study room' | 'Computer lab' | 'Meeting room';
  equipment: string[];
  color: string;
};
type Booking = {
  id: string;
  roomId: string;
  roomName: string;
  date: string;
  start: string;
  end: string;
  purpose: string;
  bookedBy: string;
  status: 'Confirmed' | 'Pending';
};

const FALLBACK_ROOMS: Room[] = [
  { id: 'R101', name: 'Study Room 101', building: 'Learning Commons', floor: '1st floor', capacity: 4, type: 'Study room', equipment: ['Whiteboard', 'Display'], color: '#DCEAFE' },
  { id: 'R204', name: 'Collaboration Room 204', building: 'Learning Commons', floor: '2nd floor', capacity: 6, type: 'Meeting room', equipment: ['Display', 'Video conferencing'], color: '#E8E2FF' },
  { id: 'LAB3', name: 'Computer Lab 3', building: 'Technology Center', floor: '3rd floor', capacity: 24, type: 'Computer lab', equipment: ['24 PCs', 'Projector'], color: '#D9F4EA' },
  { id: 'R310', name: 'Quiet Study Room 310', building: 'Library North', floor: '3rd floor', capacity: 2, type: 'Study room', equipment: ['Desk', 'Power outlets'], color: '#FFE9D7' },
  { id: 'LAB2', name: 'Computer Lab 2', building: 'Technology Center', floor: '2nd floor', capacity: 18, type: 'Computer lab', equipment: ['18 PCs', 'Projector'], color: '#DDF3F8' },
];

const TIMES = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00'];
const today = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};
const plusDays = (n: number) => {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};
const formatDate = (date: string) => new Date(`${date}T12:00:00`).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
const timeToMinutes = (time: string) => {
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
};
const FALLBACK_BOOKINGS: Booking[] = [
  { id: 'B001', roomId: 'R101', roomName: 'Study Room 101', date: today(), start: '10:00', end: '11:00', purpose: 'Group assignment', bookedBy: 'Alex Nguyen', status: 'Confirmed' },
  { id: 'B002', roomId: 'R204', roomName: 'Collaboration Room 204', date: today(), start: '14:00', end: '16:00', purpose: 'Project meeting', bookedBy: 'Taylor Tran', status: 'Confirmed' },
  { id: 'B003', roomId: 'LAB3', roomName: 'Computer Lab 3', date: plusDays(1), start: '09:00', end: '11:00', purpose: 'Programming practice', bookedBy: 'Jamie Le', status: 'Confirmed' },
];

const API_BASE_URL = 'http://localhost/room_booking_api/api.php';

async function apiRequest<T>(url: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
  });
  const payload = await response.json();
  if (!response.ok || payload.success === false) throw new Error(payload.message || `API error ${response.status}`);
  return payload.data as T;
}

export default function App() {
  const [tab, setTab] = useState<'Explore' | 'Bookings'>('Explore');
  const [rooms, setRooms] = useState<Room[]>(FALLBACK_ROOMS);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [apiStatus, setApiStatus] = useState<'loading' | 'connected' | 'error'>('loading');
  const [search, setSearch] = useState('');
  const [roomType, setRoomType] = useState('All');
  const [selectedDate, setSelectedDate] = useState(today());
  const [selectedRoom, setSelectedRoom] = useState<Room | null>(null);
  const [modalVisible, setModalVisible] = useState(false);
  const [startTime, setStartTime] = useState('09:00');
  const [endTime, setEndTime] = useState('10:00');
  const [purpose, setPurpose] = useState('');
  const [bookedBy, setBookedBy] = useState('');
  const [myBookings, setMyBookings] = useState<string[]>([]);
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const [roomData, bookingData] = await Promise.all([
          apiRequest<Room[]>(`${API_BASE_URL}?action=rooms`),
          apiRequest<Booking[]>(`${API_BASE_URL}?action=bookings`),
        ]);
        if (!active) return;
        setRooms(roomData);
        setBookings(bookingData);
        setApiStatus('connected');
      } catch {
        if (active) setApiStatus('error');
      }
    })();
    return () => { active = false; };
  }, []);

  const visibleRooms = useMemo(() => rooms.filter(room => {
    const matchesSearch = `${room.name} ${room.building} ${room.type} ${room.equipment.join(' ')}`.toLowerCase().includes(search.toLowerCase());
    return matchesSearch && (roomType === 'All' || room.type === roomType);
  }), [rooms, search, roomType]);

  const dayBookings = bookings.filter(b => b.date === selectedDate);
  const overlap = (roomId: string, date: string, start: string, end: string, excludeId?: string) =>
    bookings.some(b => b.roomId === roomId && b.date === date && b.id !== excludeId &&
      timeToMinutes(start) < timeToMinutes(b.end) && timeToMinutes(end) > timeToMinutes(b.start));

  const showMessage = (title: string, message: string) => {
    if (Platform.OS === 'web') {
      // Alert.alert is supported by React Native Web, but browser dialogs are a useful fallback.
      window.alert(`${title}\n\n${message}`);
    } else {
      Alert.alert(title, message);
    }
  };

  const openBooking = (room: Room) => {
    setSelectedRoom(room);
    setStartTime('09:00');
    setEndTime('10:00');
    setPurpose('');
    setBookedBy('');
    setModalVisible(true);
  };

  const saveBooking = async () => {
    if (!selectedRoom) return;
    if (!bookedBy.trim() || !purpose.trim()) {
      showMessage('Missing information', 'Please enter your name and booking purpose.');
      return;
    }
    if (timeToMinutes(endTime) <= timeToMinutes(startTime)) {
      showMessage('Invalid time', 'The end time must be later than the start time.');
      return;
    }
    if (apiStatus !== 'connected') {
      showMessage('API unavailable', 'Start Apache and MySQL, import the SQL file, and install the PHP API in XAMPP htdocs.');
      return;
    }
    try {
      const created = await apiRequest<Booking>(`${API_BASE_URL}?action=bookings`, {
        method: 'POST',
        body: JSON.stringify({ roomId: selectedRoom.id, date: selectedDate, start: startTime,
          end: endTime, purpose: purpose.trim(), bookedBy: bookedBy.trim() }),
      });
      setBookings(prev => [...prev, created]);
      setMyBookings(prev => [...prev, created.id]);
      setModalVisible(false);
      showMessage('Booking confirmed', `${selectedRoom.name}\n${formatDate(selectedDate)} · ${startTime}–${endTime}`);
    } catch (error) {
      showMessage('Could not create booking', error instanceof Error ? error.message : 'Please try again.');
    }
  };

  const cancelBooking = (booking: Booking) => {
    const doCancel = async () => {
      try {
        await apiRequest<unknown>(`${API_BASE_URL}?id=${encodeURIComponent(booking.id)}`, { method: 'DELETE' });
        setBookings(prev => prev.filter(b => b.id !== booking.id));
        setMyBookings(prev => prev.filter(id => id !== booking.id));
        setSelectedBooking(null);
      } catch (error) {
        showMessage('Could not cancel booking', error instanceof Error ? error.message : 'Please try again.');
      }
    };
    if (Platform.OS === 'web') {
      if (window.confirm(`Cancel booking for ${booking.roomName}?`)) void doCancel();
    } else {
      Alert.alert('Cancel booking?', `Cancel ${booking.roomName}?`, [
        { text: 'Keep booking', style: 'cancel' },
        { text: 'Cancel booking', style: 'destructive', onPress: () => { void doCancel(); } }
      ]);
    }
  };

  const renderRoom = ({ item }: { item: Room }) => {
    const reserved = dayBookings.filter(b => b.roomId === item.id).length;
    return (
      <View style={styles.roomCard}>
        <View style={[styles.roomArt, { backgroundColor: item.color }]}>
          <Ionicons name={item.type === 'Computer lab' ? 'desktop-outline' : item.type === 'Meeting room' ? 'people-outline' : 'book-outline'} size={30} color="#263C58" />
          <View style={styles.capacityBadge}><Ionicons name="people" size={12} color="#43536A" /><Text style={styles.capacityText}>{item.capacity}</Text></View>
        </View>
        <View style={styles.roomInfo}>
          <View style={styles.roomTitleRow}><Text style={styles.roomName}>{item.name}</Text><View style={styles.openDot} /></View>
          <Text style={styles.roomLocation}>{item.building} · {item.floor}</Text>
          <Text style={styles.roomType}>{item.type}</Text>
          <View style={styles.equipmentRow}>{item.equipment.slice(0, 2).map(e => <Text key={e} style={styles.equipmentChip}>{e}</Text>)}</View>
          <View style={styles.roomBottom}><Text style={styles.availability}>{reserved === 0 ? 'No bookings today' : `${reserved} booking${reserved > 1 ? 's' : ''} today`}</Text><Pressable style={styles.bookButton} onPress={() => openBooking(item)}><Text style={styles.bookButtonText}>Book room</Text></Pressable></View>
        </View>
      </View>
    );
  };

  const renderBooking = ({ item }: { item: Booking }) => (
    <Pressable style={styles.bookingCard} onPress={() => setSelectedBooking(item)}>
      <View style={styles.bookingTime}><Text style={styles.bookingStart}>{item.start}</Text><View style={styles.timeLine} /><Text style={styles.bookingEnd}>{item.end}</Text></View>
      <View style={styles.bookingContent}>
        <Text style={styles.bookingRoom}>{item.roomName}</Text>
        <Text style={styles.bookingDate}>{formatDate(item.date)} · {item.bookedBy}</Text>
        <Text style={styles.bookingPurpose}>{item.purpose}</Text>
      </View>
      <Ionicons name="chevron-forward" size={20} color="#98A2B3" />
    </Pressable>
  );

  const listData = tab === 'Explore' ? visibleRooms : bookings.filter(b => myBookings.includes(b.id));

  return (
    <SafeAreaView style={styles.safe}>
      <ExpoStatusBar style="dark" />
      <View style={styles.appHeader}>
        <View style={styles.logoCircle}><Ionicons name="calendar" size={22} color="#FFFFFF" /></View>
        <View style={{ flex: 1 }}><Text style={styles.appName}>RoomBook</Text><Text style={styles.appSubtitle}>Study spaces, made simple</Text></View>
        <Pressable style={styles.headerIcon} onPress={() => showMessage('RoomBook', 'Project 2 demo · React Native + Robin/LibCal integration-ready')}><Ionicons name="information-circle-outline" size={24} color="#344054" /></Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.pageContent} keyboardShouldPersistTaps="handled">
        <View style={styles.greetingRow}>
          <View><Text style={styles.greeting}>Find your space</Text><Text style={styles.subGreeting}>Book study rooms and computer labs.</Text></View>
          <View style={styles.dateIcon}><Ionicons name="calendar-outline" size={22} color="#3158B8" /></View>
        </View>

        <View style={styles.dateStrip}>
          {[0, 1, 2, 3, 4].map(n => {
            const date = plusDays(n);
            const active = date === selectedDate;
            return <Pressable key={date} onPress={() => setSelectedDate(date)} style={[styles.dateCell, active && styles.dateCellActive]}>
              <Text style={[styles.dateWeekday, active && styles.dateTextActive]}>{n === 0 ? 'TODAY' : new Date(`${date}T12:00:00`).toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase()}</Text>
              <Text style={[styles.dateNumber, active && styles.dateTextActive]}>{new Date(`${date}T12:00:00`).getDate()}</Text>
              <View style={[styles.dateDot, active && styles.dateDotActive]} />
            </Pressable>;
          })}
        </View>

        <View style={styles.sectionHeader}><Text style={styles.sectionTitle}>{tab === 'Explore' ? 'Available spaces' : 'My bookings'}</Text><Text style={styles.resultCount}>{tab === 'Explore' ? `${visibleRooms.length} rooms` : `${listData.length} bookings`}</Text></View>

        {tab === 'Explore' && <>
          <View style={styles.searchBar}><Ionicons name="search-outline" size={20} color="#667085" /><TextInput value={search} onChangeText={setSearch} placeholder="Search rooms, buildings, equipment" placeholderTextColor="#98A2B3" style={styles.searchInput} /></View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filterRow}>
            {['All', 'Study room', 'Computer lab', 'Meeting room'].map(type => <Pressable key={type} onPress={() => setRoomType(type)} style={[styles.filterChip, roomType === type && styles.filterChipActive]}><Text style={[styles.filterText, roomType === type && styles.filterTextActive]}>{type}</Text></Pressable>)}
          </ScrollView>
        </>}

        {tab === 'Explore' ? (
          <FlatList data={visibleRooms} keyExtractor={r => r.id} renderItem={renderRoom} scrollEnabled={false} contentContainerStyle={{ gap: 13 }} ListEmptyComponent={<Text style={styles.emptyText}>No rooms match your search.</Text>} />
        ) : (
          <FlatList data={listData as Booking[]} keyExtractor={b => b.id} renderItem={renderBooking} scrollEnabled={false} contentContainerStyle={{ gap: 12 }} ListEmptyComponent={<View style={styles.emptyState}><Ionicons name="calendar-clear-outline" size={34} color="#98A2B3" /><Text style={styles.emptyTitle}>No bookings yet</Text><Text style={styles.emptyText}>Your confirmed bookings will appear here.</Text><Pressable onPress={() => setTab('Explore')} style={styles.bookButton}><Text style={styles.bookButtonText}>Explore rooms</Text></Pressable></View>} />
        )}

        <View style={styles.integrationNote}><Ionicons name="sync-circle-outline" size={22} color="#3158B8" /><View style={{ flex: 1 }}><Text style={styles.integrationTitle}>{apiStatus === 'connected' ? 'MySQL API connected' : apiStatus === 'loading' ? 'Connecting to database…' : 'API not connected'}</Text><Text style={styles.integrationText}>{apiStatus === 'connected' ? 'Rooms and bookings are loaded from MySQL through the PHP API. Server-side conflict checks are enabled.' : 'Start Apache and MySQL, import database/room_booking_db.sql, and copy backend/room_booking_api to C:\\xampp\\htdocs\\room_booking_api. Then reload this app.'}</Text></View></View>
        <Text style={styles.footer}>RoomBook · Project 2 · React Native</Text>
      </ScrollView>

      <View style={styles.tabBar}>
        <Pressable onPress={() => setTab('Explore')} style={styles.tabItem}><Ionicons name={tab === 'Explore' ? 'compass' : 'compass-outline'} size={22} color={tab === 'Explore' ? '#3158B8' : '#98A2B3'} /><Text style={[styles.tabLabel, tab === 'Explore' && styles.tabLabelActive]}>Explore</Text></Pressable>
        <Pressable onPress={() => setTab('Bookings')} style={styles.tabItem}><Ionicons name={tab === 'Bookings' ? 'calendar' : 'calendar-outline'} size={22} color={tab === 'Bookings' ? '#3158B8' : '#98A2B3'} /><Text style={[styles.tabLabel, tab === 'Bookings' && styles.tabLabelActive]}>My bookings</Text>{myBookings.length > 0 && <View style={styles.tabBadge}><Text style={styles.tabBadgeText}>{myBookings.length}</Text></View>}</Pressable>
      </View>

      <Modal visible={modalVisible} animationType="slide" transparent onRequestClose={() => setModalVisible(false)}>
        <View style={styles.modalBackdrop}><View style={styles.modalSheet}>
          <View style={styles.modalHandle} />
          <View style={styles.modalHeader}><View style={{ flex: 1 }}><Text style={styles.modalEyebrow}>NEW RESERVATION</Text><Text style={styles.modalTitle}>Book a room</Text><Text style={styles.modalSubtitle}>{selectedRoom?.name} · {formatDate(selectedDate)}</Text></View><Pressable onPress={() => setModalVisible(false)} style={styles.closeButton}><Ionicons name="close" size={22} color="#475467" /></Pressable></View>
          <Text style={styles.fieldLabel}>Start time</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.timeOptions}>{TIMES.slice(0, -1).map(t => <Pressable key={t} onPress={() => { setStartTime(t); const next = TIMES[TIMES.indexOf(t) + 1]; if (timeToMinutes(endTime) <= timeToMinutes(t)) setEndTime(next); }} style={[styles.timeChip, startTime === t && styles.timeChipActive]}><Text style={[styles.timeChipText, startTime === t && styles.timeChipTextActive]}>{t}</Text></Pressable>)}</ScrollView>
          <Text style={styles.fieldLabel}>End time</Text><ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.timeOptions}>{TIMES.filter(t => timeToMinutes(t) > timeToMinutes(startTime)).map(t => <Pressable key={t} onPress={() => setEndTime(t)} style={[styles.timeChip, endTime === t && styles.timeChipActive]}><Text style={[styles.timeChipText, endTime === t && styles.timeChipTextActive]}>{t}</Text></Pressable>)}</ScrollView>
          <Text style={styles.fieldLabel}>Your name</Text><TextInput value={bookedBy} onChangeText={setBookedBy} placeholder="Enter your name" style={styles.fieldInput} />
          <Text style={styles.fieldLabel}>Booking purpose</Text><TextInput value={purpose} onChangeText={setPurpose} placeholder="e.g. Group assignment" style={styles.fieldInput} />
          {selectedRoom && overlap(selectedRoom.id, selectedDate, startTime, endTime) && <Text style={styles.conflictText}>This time overlaps an existing booking.</Text>}
          <Pressable style={styles.confirmButton} onPress={saveBooking}><Text style={styles.confirmButtonText}>Confirm booking</Text><Ionicons name="arrow-forward" size={18} color="#fff" /></Pressable>
          <Text style={styles.modalDisclaimer}>Demo mode: booking data is stored locally until the app is closed.</Text>
        </View></View>
      </Modal>

      <Modal visible={!!selectedBooking} animationType="fade" transparent onRequestClose={() => setSelectedBooking(null)}>
        <View style={styles.modalBackdrop}><View style={styles.detailSheet}>
          <Text style={styles.modalEyebrow}>BOOKING DETAILS</Text><Text style={styles.modalTitle}>{selectedBooking?.roomName}</Text><Text style={styles.detailLine}>{selectedBooking ? formatDate(selectedBooking.date) : ''} · {selectedBooking?.start}–{selectedBooking?.end}</Text><Text style={styles.detailLine}>Booked by: {selectedBooking?.bookedBy}</Text><Text style={styles.detailLine}>Purpose: {selectedBooking?.purpose}</Text>
          <Pressable style={styles.cancelBookingButton} onPress={() => selectedBooking && cancelBooking(selectedBooking)}><Text style={styles.cancelBookingText}>Cancel booking</Text></Pressable><Pressable style={styles.closeDetailButton} onPress={() => setSelectedBooking(null)}><Text style={styles.closeDetailText}>Close</Text></Pressable>
        </View></View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F5F7FB', paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0 },
  appHeader: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 20, paddingVertical: 14, backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderBottomColor: '#E9EDF4', gap: 11 },
  logoCircle: { width: 43, height: 43, borderRadius: 14, backgroundColor: '#3158B8', alignItems: 'center', justifyContent: 'center' },
  appName: { fontSize: 20, fontWeight: '800', color: '#172B4D', letterSpacing: -0.4 },
  appSubtitle: { fontSize: 11, color: '#7B879B', marginTop: 2 },
  headerIcon: { padding: 6 },
  pageContent: { padding: 20, paddingBottom: 30 },
  greetingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  greeting: { fontSize: 27, fontWeight: '800', color: '#172B4D', letterSpacing: -0.8 },
  subGreeting: { fontSize: 13, color: '#7B879B', marginTop: 5 },
  dateIcon: { height: 43, width: 43, borderRadius: 14, backgroundColor: '#E7EDFF', alignItems: 'center', justifyContent: 'center' },
  dateStrip: { flexDirection: 'row', gap: 8, marginBottom: 27 },
  dateCell: { flex: 1, minWidth: 50, alignItems: 'center', justifyContent: 'center', backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E6EAF1', borderRadius: 14, paddingVertical: 11 },
  dateCellActive: { backgroundColor: '#3158B8', borderColor: '#3158B8' },
  dateWeekday: { color: '#7B879B', fontSize: 9, fontWeight: '800', letterSpacing: 0.5 },
  dateNumber: { color: '#172B4D', fontSize: 20, fontWeight: '800', marginTop: 5 },
  dateTextActive: { color: '#FFFFFF' },
  dateDot: { width: 4, height: 4, borderRadius: 2, backgroundColor: 'transparent', marginTop: 4 },
  dateDotActive: { backgroundColor: '#FFFFFF' },
  sectionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 13 },
  sectionTitle: { fontSize: 19, fontWeight: '800', color: '#172B4D' },
  resultCount: { fontSize: 12, color: '#7B879B', fontWeight: '600' },
  searchBar: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E2E7EF', borderRadius: 12, paddingHorizontal: 12, height: 47, gap: 8, marginBottom: 12 },
  searchInput: { flex: 1, fontSize: 13, color: '#172B4D', paddingVertical: 0 },
  filterRow: { gap: 8, paddingBottom: 15 },
  filterChip: { borderWidth: 1, borderColor: '#E0E6EF', borderRadius: 100, paddingVertical: 8, paddingHorizontal: 13, backgroundColor: '#FFFFFF' },
  filterChipActive: { borderColor: '#3158B8', backgroundColor: '#E7EDFF' },
  filterText: { fontSize: 11, fontWeight: '700', color: '#667085' },
  filterTextActive: { color: '#3158B8' },
  roomCard: { backgroundColor: '#FFFFFF', borderRadius: 17, borderWidth: 1, borderColor: '#E8ECF3', overflow: 'hidden', flexDirection: 'row', padding: 12, gap: 13 },
  roomArt: { width: 86, minHeight: 120, borderRadius: 13, alignItems: 'center', justifyContent: 'center', position: 'relative' },
  capacityBadge: { position: 'absolute', bottom: 7, left: 7, right: 7, backgroundColor: '#FFFFFFCC', borderRadius: 7, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 4, paddingVertical: 4 },
  capacityText: { color: '#43536A', fontSize: 11, fontWeight: '800' },
  roomInfo: { flex: 1, minWidth: 0, paddingVertical: 2 },
  roomTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  roomName: { flex: 1, fontSize: 14, color: '#172B4D', fontWeight: '800' },
  openDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: '#12B76A' },
  roomLocation: { fontSize: 11, color: '#667085', marginTop: 5 },
  roomType: { fontSize: 10, fontWeight: '700', color: '#3158B8', marginTop: 4 },
  equipmentRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 5, marginTop: 8 },
  equipmentChip: { color: '#667085', backgroundColor: '#F2F4F7', borderRadius: 5, fontSize: 9, paddingHorizontal: 6, paddingVertical: 4 },
  roomBottom: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 5, marginTop: 10 },
  availability: { flex: 1, fontSize: 10, color: '#667085' },
  bookButton: { backgroundColor: '#3158B8', paddingHorizontal: 11, paddingVertical: 8, borderRadius: 8 },
  bookButtonText: { color: '#FFFFFF', fontSize: 10, fontWeight: '800' },
  bookingCard: { backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E8ECF3', borderRadius: 15, padding: 14, flexDirection: 'row', alignItems: 'center', gap: 12 },
  bookingTime: { width: 53, alignItems: 'center' },
  bookingStart: { fontSize: 13, fontWeight: '800', color: '#3158B8' },
  timeLine: { height: 15, width: 2, backgroundColor: '#D5DDF1', marginVertical: 3 },
  bookingEnd: { fontSize: 11, color: '#7B879B' },
  bookingContent: { flex: 1 },
  bookingRoom: { fontSize: 14, fontWeight: '800', color: '#172B4D' },
  bookingDate: { fontSize: 11, color: '#7B879B', marginTop: 4 },
  bookingPurpose: { fontSize: 12, color: '#475467', marginTop: 6 },
  emptyState: { backgroundColor: '#FFFFFF', borderRadius: 16, borderWidth: 1, borderColor: '#E8ECF3', padding: 28, alignItems: 'center', gap: 9 },
  emptyTitle: { fontSize: 16, fontWeight: '800', color: '#172B4D' },
  emptyText: { color: '#7B879B', fontSize: 12, textAlign: 'center', paddingVertical: 16 },
  integrationNote: { flexDirection: 'row', gap: 10, padding: 14, borderRadius: 14, backgroundColor: '#EAF0FF', marginTop: 23, alignItems: 'flex-start' },
  integrationTitle: { color: '#274A9D', fontSize: 12, fontWeight: '800' },
  integrationText: { color: '#4C5F87', fontSize: 11, lineHeight: 17, marginTop: 4 },
  footer: { textAlign: 'center', color: '#98A2B3', fontSize: 10, marginTop: 23, marginBottom: 8 },
  tabBar: { flexDirection: 'row', justifyContent: 'space-around', paddingTop: 10, paddingBottom: Platform.OS === 'ios' ? 20 : 10, backgroundColor: '#FFFFFF', borderTopWidth: 1, borderTopColor: '#E8ECF3' },
  tabItem: { minWidth: 100, alignItems: 'center', justifyContent: 'center', gap: 4, position: 'relative', paddingHorizontal: 15 },
  tabLabel: { color: '#98A2B3', fontSize: 10, fontWeight: '700' },
  tabLabelActive: { color: '#3158B8' },
  tabBadge: { position: 'absolute', top: -2, right: 16, minWidth: 15, height: 15, borderRadius: 8, backgroundColor: '#D92D20', alignItems: 'center', justifyContent: 'center' },
  tabBadgeText: { color: '#FFFFFF', fontSize: 8, fontWeight: '800' },
  modalBackdrop: { flex: 1, backgroundColor: '#10182880', justifyContent: 'flex-end' },
  modalSheet: { backgroundColor: '#FFFFFF', borderTopLeftRadius: 24, borderTopRightRadius: 24, paddingHorizontal: 21, paddingTop: 10, paddingBottom: 28, maxHeight: '92%' },
  modalHandle: { width: 42, height: 4, borderRadius: 3, backgroundColor: '#D0D5DD', alignSelf: 'center', marginBottom: 18 },
  modalHeader: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 18 },
  modalEyebrow: { fontSize: 10, color: '#3158B8', fontWeight: '800', letterSpacing: 1.2 },
  modalTitle: { fontSize: 24, fontWeight: '800', color: '#172B4D', marginTop: 5 },
  modalSubtitle: { color: '#667085', fontSize: 12, marginTop: 5 },
  closeButton: { height: 36, width: 36, backgroundColor: '#F2F4F7', borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  fieldLabel: { fontSize: 12, fontWeight: '800', color: '#344054', marginBottom: 8, marginTop: 4 },
  timeOptions: { gap: 7, paddingBottom: 13 },
  timeChip: { borderWidth: 1, borderColor: '#E0E6EF', backgroundColor: '#FFFFFF', paddingHorizontal: 12, paddingVertical: 9, borderRadius: 9 },
  timeChipActive: { borderColor: '#3158B8', backgroundColor: '#E7EDFF' },
  timeChipText: { color: '#667085', fontSize: 12, fontWeight: '700' },
  timeChipTextActive: { color: '#3158B8' },
  fieldInput: { borderWidth: 1, borderColor: '#D0D5DD', borderRadius: 10, paddingHorizontal: 12, paddingVertical: 12, fontSize: 13, color: '#172B4D', marginBottom: 11 },
  conflictText: { color: '#B42318', fontSize: 11, marginBottom: 10, fontWeight: '700' },
  confirmButton: { backgroundColor: '#3158B8', minHeight: 48, borderRadius: 12, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 9, marginTop: 5 },
  confirmButtonText: { color: '#FFFFFF', fontSize: 14, fontWeight: '800' },
  modalDisclaimer: { color: '#98A2B3', textAlign: 'center', fontSize: 10, marginTop: 12 },
  detailSheet: { backgroundColor: '#FFFFFF', borderRadius: 22, margin: 22, padding: 23 },
  detailLine: { color: '#475467', fontSize: 13, marginTop: 12 },
  cancelBookingButton: { marginTop: 22, backgroundColor: '#FEE4E2', borderRadius: 11, padding: 13, alignItems: 'center' },
  cancelBookingText: { color: '#B42318', fontWeight: '800', fontSize: 13 },
  closeDetailButton: { marginTop: 9, padding: 12, alignItems: 'center' },
  closeDetailText: { color: '#475467', fontWeight: '700' }
});
